import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/geo.dart';
import '../../app/heading.dart';
import '../../app/member.dart';
import '../../app/radar.dart';
import '../../app/sensors.dart';
import '../../app/compass_heading_provider.dart';
import '../app_repository.dart';
import '../app_scope.dart';
import '../theme.dart';
import '../widgets/radar_view.dart';

/// Écran radar : oriente selon le cap (repli nord-en-haut), affiche plusieurs
/// amis colorés, liste rétractable de sélection, localisation momentanée /
/// session 5 min. [headingProvider] est injectable pour les tests.
class RadarScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final HeadingProvider? headingProvider;
  const RadarScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.headingProvider,
  });

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  late final HeadingProvider _heading;
  late final Stream<HeadingReading> _headingStream;
  final Set<String> _hidden = {};
  bool _listExpanded = true;
  int? _sessionEndMs;
  Timer? _ticker;
  int _lastLiveRequestMs = 0; // dernière re-demande pendant la session
  GeoPoint? _me; // ma position courante (GPS sur mobile) ; null tant qu'inconnue
  bool _meInit = false;
  StreamSubscription<GeoPoint>? _posSub; // suit ma position tant que l'écran vit

  /// Pendant une session, on redemande la position des amis à cet intervalle
  /// (sinon le « il y a … » ne ferait que grandir).
  static const int _liveRequestIntervalMs = 10000;

  @override
  void initState() {
    super.initState();
    _heading = widget.headingProvider ?? defaultHeadingProvider();
    // Une seule souscription pour toute la vie de l'écran : `readings()` n'est
    // appelé qu'ici (le lisseur du provider est à état — cf. Plan B).
    _headingStream = _heading.readings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_meInit) return;
    _meInit = true;
    _startPositionUpdates();
  }

  /// Fix immédiat puis suivi continu de ma position tant que l'écran est ouvert,
  /// pour que le centre du radar (et donc la distance affichée) reste à jour même
  /// sur une demande momentanée.
  Future<void> _startPositionUpdates() async {
    final repo = AppScope.of(context);
    await _refreshMe(); // valeur immédiate + déclenche la demande de permission
    if (!mounted) return;
    _posSub = repo.positionUpdates().listen((g) {
      if (mounted) setState(() => _me = g);
    });
  }

  /// Met à jour [_me] avec ma position courante (vrai GPS sur mobile).
  Future<void> _refreshMe() async {
    final repo = AppScope.of(context);
    await repo.ensureConnected();
    final pos = await repo.currentPosition();
    if (!mounted) return;
    setState(() => _me = pos);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _request({required bool live}) async {
    final repo = AppScope.of(context);
    await repo.ensureConnected();
    await repo.requestLocation(
        groupId: widget.groupId, targetId: kAllMembers, live: live);
    if (!mounted) return;
    await _refreshMe(); // rafraîchit aussi ma propre position (centre du radar)
    if (!mounted) return;
    if (live) {
      final startMs = DateTime.now().millisecondsSinceEpoch;
      _lastLiveRequestMs = startMs;
      setState(() => _sessionEndMs = startMs + kSessionDurationMs);
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final end = _sessionEndMs;
        if (!mounted || end == null || nowMs >= end) {
          t.cancel();
          if (mounted) setState(() => _sessionEndMs = null);
          return;
        }
        // Redemande régulièrement pour rafraîchir la position des amis.
        if (nowMs - _lastLiveRequestMs >= _liveRequestIntervalMs) {
          _lastLiveRequestMs = nowMs;
          AppScope.of(context).requestLocation(
              groupId: widget.groupId, targetId: kAllMembers, live: true);
        }
        setState(() {}); // décompte + fraîcheur ; ma position via _posSub
      });
    }
  }

  /// Arrête la session en cours (le bouton compteur).
  void _stopSession() {
    _ticker?.cancel();
    setState(() => _sessionEndMs = null);
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: repo,
          builder: (context, _) {
            // On ne se localise pas soi-même : exclure son propre identifiant.
            final myId = repo.identity?.memberId;
            final members = repo
                .members(widget.groupId)
                .where((m) => m.memberId != myId)
                .toList();
            return StreamBuilder<HeadingReading>(
              stream: _headingStream,
              builder: (context, snap) {
                final reading = snap.data;
                final headingDeg = reading?.degrees ?? 0;
                final me = _me ?? repo.myPosition;
                final now = DateTime.now().millisecondsSinceEpoch;
                final inputs = [
                  for (final m in members)
                    if (!_hidden.contains(m.memberId))
                      RadarInput(m.memberId, m.name, repo.located(m.memberId)),
                ];
                final targets = buildRadarTargets(
                    me: me,
                    headingDegrees: headingDeg,
                    inputs: inputs,
                    nowMs: now);
                return Column(
                  children: [
                    _banner(context, p),
                    if (reading == null)
                      _note(p, 'Boussole indisponible — radar nord en haut'),
                    if (reading != null &&
                        reading.reliability != HeadingReliability.good)
                      _note(p, 'Boussole peu fiable — calibre-la (geste en 8)'),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                            child: RadarView(
                                targets: targets,
                                headingDegrees: headingDeg)),
                      ),
                    ),
                    _list(context, repo, members, me, now, p),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _banner(BuildContext context, AppPalette p) {
    final end = _sessionEndMs;
    final remaining = end == null
        ? null
        : sessionRemainingSeconds(end, DateTime.now().millisecondsSinceEpoch);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(widget.groupName,
                style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          IconButton(
            tooltip: 'Localisation momentanée',
            icon: const Icon(Icons.place_outlined),
            onPressed: () => _request(live: false),
          ),
          if (remaining == null)
            IconButton(
              tooltip: 'Session 5 min',
              icon: const Icon(Icons.timer_outlined),
              onPressed: () => _request(live: true),
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.stop_circle_outlined, size: 18),
              label: Text(_mmss(remaining)),
              onPressed: _stopSession,
            ),
        ],
      ),
    );
  }

  Widget _note(AppPalette p, String text) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration:
            BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(color: p.textMuted, fontSize: 12)),
      );

  Widget _list(BuildContext context, AppRepository repo,
      List<GroupMember> members, GeoPoint me, int now, AppPalette p) {
    final shownCount =
        members.where((m) => !_hidden.contains(m.memberId)).length;
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _listExpanded = !_listExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Amis · $shownCount affichés',
                        style: TextStyle(color: p.textPrimary, fontSize: 13)),
                  ),
                  Icon(_listExpanded ? Icons.expand_less : Icons.expand_more,
                      color: p.textMuted),
                ],
              ),
            ),
          ),
          if (_listExpanded)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final m in members) _row(m, repo.located(m.memberId), me, now, p),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(GroupMember m, LocatedPosition? fix, GeoPoint me, int now,
      AppPalette p) {
    final shown = !_hidden.contains(m.memberId);
    final String subtitle;
    if (fix == null) {
      subtitle = 'en attente…';
    } else {
      final age = ((now - fix.timestampMs) / 1000).floor();
      subtitle =
          '${RadarView.formatDistance(distanceMeters(me, fix.point))} · il y a ${_freshness(age < 0 ? 0 : age)}';
    }
    return Opacity(
      opacity: shown ? 1 : 0.45,
      child: ListTile(
        dense: true,
        title:
            Text(m.name, style: TextStyle(color: p.textPrimary, fontSize: 13)),
        subtitle:
            Text(subtitle, style: TextStyle(color: p.textMuted, fontSize: 11)),
        trailing: Checkbox(
          value: shown,
          onChanged: (v) => setState(() {
            if (v == true) {
              _hidden.remove(m.memberId);
            } else {
              _hidden.add(m.memberId);
            }
          }),
        ),
      ),
    );
  }

  static String _freshness(int seconds) {
    if (seconds < 60) return '$seconds s';
    if (seconds < 3600) return '${seconds ~/ 60} min';
    return '${seconds ~/ 3600} h';
  }

  static String _mmss(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

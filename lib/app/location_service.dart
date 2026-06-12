import 'dart:math';
import 'dart:typed_data';
import '../crypto/envelope.dart';
import '../crypto/group.dart';
import '../crypto/identity.dart';
import '../crypto/messages.dart';
import '../mesh/msg_id.dart';
import 'geo.dart';
import 'member.dart';
import 'sensors.dart';

const int kTypeRequest = 1;
const int kTypeResponse = 2;

/// Position localisée d'un ami, remontée au demandeur.
class LocatedPosition {
  final String responderId;
  final GeoPoint point;
  final double accuracyMeters;
  final int timestampMs;
  const LocatedPosition(this.responderId, this.point, this.accuracyMeters, this.timestampMs);
}

/// Orchestration du protocole de localisation au-dessus du mesh + crypto.
class LocationService {
  final Identity identity;
  final String myId;
  final List<Group> groups;
  final LocationProvider location;
  final Random random;
  final int Function() nowMs;
  final void Function(Uint8List sealedFrame) broadcast;
  final int replayWindowMs;
  final int defaultTtl;
  final int pendingTtlMs;

  final Map<String, _PendingRequest> _pending = {};

  void Function(LocatedPosition position)? onLocated;

  LocationService({
    required this.identity,
    required this.myId,
    required this.groups,
    required this.location,
    required this.random,
    required this.nowMs,
    required this.broadcast,
    this.replayWindowMs = 30000,
    this.defaultTtl = 8,
    this.pendingTtlMs = 300000,
  });

  Group? _groupById(String groupId) {
    for (final g in groups) {
      if (g.groupId == groupId) return g;
    }
    return null;
  }

  /// Identifiant de corrélation de requête : hex aléatoire (32 chars).
  String _newRequestId() => memberId(generateMsgId(random));

  void _prunePending() {
    final now = nowMs();
    _pending.removeWhere((_, p) => p.expiry <= now);
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Demande la localisation de [targetId] (ou `kAllMembers`) dans [groupId].
  Future<void> requestLocation({
    required String groupId,
    required String targetId,
    bool live = false,
  }) async {
    final group = _groupById(groupId);
    if (group == null) return;
    final requestId = _newRequestId();
    _pending[requestId] = _PendingRequest(nowMs() + pendingTtlMs, targetId);
    final payload = LocationRequest(
      requestId: requestId, targetId: targetId, live: live).encode();
    final env = await Envelope.seal(
      type: kTypeRequest, ttl: defaultTtl, sender: identity, group: group,
      payload: payload, msgId: generateMsgId(random), timestampMs: nowMs());
    broadcast(env.toBytes());
  }

  /// Reçoit une trame livrée par le mesh. Tente de l'ouvrir contre chaque groupe.
  Future<void> handleIncoming(Uint8List frame) async {
    final Envelope env;
    try {
      env = Envelope.fromBytes(frame);
    } catch (_) {
      return;
    }
    for (final group in groups) {
      Uint8List payload;
      try {
        payload = await env.open(group);
      } catch (_) {
        continue;
      }
      _prunePending();
      if (env.type == kTypeRequest) {
        await _onRequest(group, env.timestampMs, env.senderPub, payload);
      } else if (env.type == kTypeResponse) {
        _onResponse(payload);
      }
      return;
    }
  }

  Future<void> _onRequest(Group group, int requestTs, List<int> senderPub, Uint8List payload) async {
    if (_bytesEqual(senderPub, identity.signPublicKey)) return; // ne pas se localiser soi-même
    final req = LocationRequest.decode(payload);
    if ((nowMs() - requestTs).abs() > replayWindowMs) return; // rejette le passé ET le futur (anti-skew)
    if (req.targetId != kAllMembers && req.targetId != myId) return;
    final fix = await location.current();
    if (fix == null) return; // pas de position fiable -> on ne répond pas
    final respPayload = LocationResponse(
      requestId: req.requestId,
      responderId: myId,
      latitude: fix.point.latitude,
      longitude: fix.point.longitude,
      accuracyMeters: fix.accuracyMeters,
      timestampMs: nowMs(),
    ).encode();
    final env = await Envelope.seal(
      type: kTypeResponse, ttl: defaultTtl, sender: identity, group: group,
      payload: respPayload, msgId: generateMsgId(random), timestampMs: nowMs());
    broadcast(env.toBytes());
  }

  void _onResponse(Uint8List payload) {
    final res = LocationResponse.decode(payload);
    final pending = _pending[res.requestId];
    if (pending == null) return;
    // Pour une demande ciblée, seul le membre visé est une réponse valide.
    if (pending.targetId != kAllMembers && res.responderId != pending.targetId) return;
    // Déduplication : un même répondeur ne déclenche onLocated qu'une fois.
    if (!pending.respondedBy.add(res.responderId)) return;
    // (Pas de rejet sur l'horodatage : le requestId en attente borne déjà le
    // rejeu. Le timestamp ne sert qu'à la fraîcheur d'affichage côté UI, ce qui
    // évite de jeter une réponse valide en cas de dérive d'horloge entre appareils.)
    onLocated?.call(LocatedPosition(
      res.responderId,
      GeoPoint(res.latitude, res.longitude),
      res.accuracyMeters,
      res.timestampMs,
    ));
  }
}

class _PendingRequest {
  final int expiry;
  final String targetId;
  final Set<String> respondedBy = {};
  _PendingRequest(this.expiry, this.targetId);
}

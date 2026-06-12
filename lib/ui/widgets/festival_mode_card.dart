import 'dart:io';
import 'package:flutter/material.dart';
import '../festival_mode.dart';
import '../theme.dart';
import 'app_card.dart';

/// Carte proéminente d'activation du « mode festival » : rend l'appareil
/// localisable même appli en arrière-plan. Placée en haut de l'écran d'accueil.
class FestivalModeCard extends StatefulWidget {
  const FestivalModeCard({super.key});
  @override
  State<FestivalModeCard> createState() => _FestivalModeCardState();
}

class _FestivalModeCardState extends State<FestivalModeCard>
    with WidgetsBindingObserver {
  bool _on = false;
  bool _always = false; // localisation « tout le temps » (arrière-plan)
  bool _battery = true; // true = exempté d'optimisation batterie (pas de bridage)
  bool _busy = false;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      WidgetsBinding.instance.addObserver(this);
      _refresh();
    }
  }

  @override
  void dispose() {
    if (_isMobile) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Au retour des réglages système (où l'utilisateur a pu changer la
    // permission), on resynchronise l'état affiché.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final on = await FestivalMode.isOn();
    final always = await FestivalMode.isAlways();
    final battery = await FestivalMode.isBatteryUnrestricted();
    if (!mounted) return;
    setState(() {
      _on = on;
      _always = always;
      _battery = battery;
    });
  }

  Future<void> _toggle(bool v) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (v) {
      final ok = await FestivalMode.start();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Autorise la localisation et les notifications '
                'pour activer le mode festival.')));
        setState(() {
          _on = false;
          _busy = false;
        });
        return;
      }
      if (!mounted) return;
      await _refresh(); // _on / _always / _battery
      if (!mounted) return;
      setState(() => _busy = false);
    } else {
      await FestivalMode.stop();
      if (!mounted) return;
      setState(() {
        _on = false;
        _busy = false;
      });
    }
  }

  Future<void> _requestAlways() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await FestivalMode.requestAlways();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Choisis « Autoriser tout le temps » dans les '
              'réglages, puis reviens.')));
    }
    final always = await FestivalMode.isAlways();
    if (!mounted) return;
    setState(() {
      _always = always;
      _busy = false;
    });
  }

  Future<void> _requestBattery() async {
    if (_busy) return;
    setState(() => _busy = true);
    await FestivalMode.requestBatteryUnrestricted();
    if (!mounted) return;
    final battery = await FestivalMode.isBatteryUnrestricted();
    if (!mounted) return;
    setState(() {
      _battery = battery;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _on ? p.accentSoft : p.raised,
                    borderRadius: BorderRadius.circular(11)),
                child: Icon(_on ? Icons.podcasts : Icons.podcasts_outlined,
                    size: 20, color: _on ? p.accent : p.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mode festival',
                        style: TextStyle(color: p.textPrimary, fontSize: 15)),
                    Text(
                      _on
                          ? 'Localisable en arrière-plan'
                          : 'Autoriser ma localisation en arrière-plan',
                      style: TextStyle(color: p.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(value: _on, onChanged: _busy ? null : _toggle),
            ],
          ),
          // Mode actif mais permission seulement « pendant l'utilisation » :
          // proposer « tout le temps » pour la fiabilité en veille.
          if (_on && !_always)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _busy ? null : _requestAlways,
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: const Text('Autoriser tout le temps (veille)'),
              ),
            ),
          // Mode actif mais optimisation batterie active : la lever améliore
          // nettement la disponibilité en arrière-plan.
          if (_on && !_battery)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _busy ? null : _requestBattery,
                icon: const Icon(Icons.battery_saver_outlined, size: 18),
                label: const Text('Désactiver l\'optimisation batterie'),
              ),
            ),
        ],
      ),
    );
  }
}

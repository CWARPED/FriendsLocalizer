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

class _FestivalModeCardState extends State<FestivalModeCard> {
  bool _on = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Le service n'existe que sur mobile ; ailleurs (desktop/test) on n'appelle
    // pas le plugin natif.
    if (Platform.isAndroid || Platform.isIOS) {
      FestivalMode.isOn().then((v) {
        if (mounted) setState(() => _on = v);
      });
    }
  }

  Future<void> _toggle(bool v) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (v) {
      final ok = await FestivalMode.start();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Autorise la localisation « tout le temps » et les notifications '
                'pour rester localisable.')));
        setState(() {
          _on = false;
          _busy = false;
        });
        return;
      }
      setState(() {
        _on = true;
        _busy = false;
      });
    } else {
      await FestivalMode.stop();
      if (!mounted) return;
      setState(() {
        _on = false;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return AppCard(
      child: Row(
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
                      ? 'Tu es localisable même appli fermée'
                      : 'Localisation en arrière-plan désactivée',
                  style: TextStyle(color: p.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: _on, onChanged: _busy ? null : _toggle),
        ],
      ),
    );
  }
}

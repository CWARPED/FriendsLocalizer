import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'app_card.dart';

/// Carte de statut GPS (mobile uniquement). Affiche l'état de la permission de
/// localisation et propose un bouton pour l'autoriser.
///
/// ADAPTATEUR DEVICE : non testé unitairement (plugin natif). N'est affichée
/// que sur mobile par l'écran Réglages.
class GpsStatusCard extends StatefulWidget {
  const GpsStatusCard({super.key});
  @override
  State<GpsStatusCard> createState() => _GpsStatusCardState();
}

class _GpsStatusCardState extends State<GpsStatusCard> {
  String _status = 'Vérification…';
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    String status;
    var granted = false;
    if (!await Geolocator.isLocationServiceEnabled()) {
      status = 'Service de localisation désactivé';
    } else {
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.whileInUse ||
          p == LocationPermission.always) {
        status = 'Position GPS active';
        granted = true;
      } else if (p == LocationPermission.deniedForever) {
        status = 'Autorisation refusée (à activer dans les réglages système)';
      } else {
        status = 'Autorisation requise';
      }
    }
    if (!mounted) return;
    setState(() {
      _status = status;
      _granted = granted;
    });
  }

  Future<void> _request() async {
    await Geolocator.requestPermission();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_granted ? Icons.location_on : Icons.location_off, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_status)),
            ],
          ),
          if (!_granted) ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _request,
              child: const Text('Autoriser la localisation'),
            ),
          ],
        ],
      ),
    );
  }
}

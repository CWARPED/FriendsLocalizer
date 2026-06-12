import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/onboarding.dart';
import '../app_scope.dart';

/// Scanne un QR d'invitation, confirme le nom du groupe, puis rejoint.
/// ADAPTATEUR DEVICE : n'est ouvert que sur mobile (cf. JoinGroupScreen).
class ScanInviteScreen extends StatefulWidget {
  const ScanInviteScreen({super.key});
  @override
  State<ScanInviteScreen> createState() => _ScanInviteScreenState();
}

class _ScanInviteScreenState extends State<ScanInviteScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false; // évite les dialogues multiples

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final payload = extractInvitePayload(raw);
      final invite = tryDecodeInvite(payload);
      if (invite == null) continue; // QR non-invitation : ignorer

      _handling = true;
      await _controller.stop();
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rejoindre le groupe ?'),
          content: Text('« ${invite.groupName} »'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Rejoindre')),
          ],
        ),
      );

      if (ok == true) {
        if (!mounted) return;
        await AppScope.of(context).joinFromInvite(payload);
        if (!mounted) return;
        Navigator.popUntil(context, (r) => r.isFirst); // retour accueil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Groupe « ${invite.groupName} » rejoint')),
        );
      } else {
        await _controller.start(); // reprend le scan
        _handling = false;
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner le QR')),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }
}

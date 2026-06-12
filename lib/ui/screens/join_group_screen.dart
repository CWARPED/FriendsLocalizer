import 'dart:io';

import 'package:flutter/material.dart';
import '../../app/onboarding.dart';
import '../app_scope.dart';
import '../theme.dart';
import '../widgets/app_card.dart';
import 'scan_invite_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});
  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() => _error = null);
    try {
      await AppScope.of(context).joinFromInvite(extractInvitePayload(_controller.text));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _error = 'Invitation invalide');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canScan = Platform.isAndroid || Platform.isIOS;
    return Scaffold(
      appBar: AppBar(title: const Text('Rejoindre un groupe')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              onTap: canScan
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScanInviteScreen()))
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner,
                      size: 30,
                      color: canScan
                          ? Theme.of(context)
                              .extension<AppPalette>()!
                              .accentSoft
                          : Theme.of(context)
                              .extension<AppPalette>()!
                              .textMuted),
                  const SizedBox(height: 8),
                  Text(
                      canScan
                          ? 'Scanner un QR code'
                          : 'Scanner un QR (caméra indisponible ici)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context)
                              .extension<AppPalette>()!
                              .textMuted,
                          fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('— ou colle le lien d\'invitation —',
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Lien fl://join#…',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _join, child: const Text('Rejoindre')),
            ),
          ],
        ),
      ),
    );
  }
}

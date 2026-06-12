import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../app_scope.dart';
import '../theme.dart';

class InviteScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  const InviteScreen(
      {super.key, required this.groupId, required this.groupName});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final payload = AppScope.of(context).inviteFor(groupId);
    final link = 'fl://join#$payload';
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter au $groupName')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Fais scanner ce QR, ou partage le lien',
                style: TextStyle(color: p.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: payload, size: 200),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Lien d\'invitation',
                  style: TextStyle(color: p.textMuted, fontSize: 11)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              decoration: BoxDecoration(
                  color: p.inset, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.textPrimary, fontSize: 12)),
                  ),
                  IconButton(
                    tooltip: 'Copier le lien',
                    icon: Icon(Icons.copy, size: 18, color: p.accentSoft),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: link)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.ios_share),
                label: const Text('Partager le lien'),
                onPressed: () => Share.share(link),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

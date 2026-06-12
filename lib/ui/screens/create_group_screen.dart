import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_scope.dart';
import '../theme.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _controller = TextEditingController();
  String? _invitePayload;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final repo = AppScope.of(context);
    final group = await repo.createGroup(name);
    if (!mounted) return;
    setState(() => _invitePayload = repo.inviteFor(group.id));
  }

  @override
  Widget build(BuildContext context) {
    final payload = _invitePayload;
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau groupe')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: payload == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Donne un nom à ton groupe. Tu pourras ensuite inviter '
                      'tes amis avec un QR ou un lien.',
                      style: TextStyle(
                          color: Theme.of(context)
                              .extension<AppPalette>()!
                              .textMuted,
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nom du groupe',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        onPressed: _create,
                        label: const Text('Créer')),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(data: payload, size: 200),
                    ),
                    const SizedBox(height: 16),
                    const Text('Fais scanner ce QR, ou partage le lien :'),
                    const SizedBox(height: 8),
                    SelectableText(
                      'fl://join#$payload',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier le lien'),
                      onPressed: () => Clipboard.setData(
                          ClipboardData(text: 'fl://join#$payload')),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

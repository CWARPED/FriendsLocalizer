import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await AppScope.of(context).createIdentity(name);
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: p.raised, borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.radar, size: 36, color: p.accentSoft),
              ),
              const SizedBox(height: 16),
              Text('FriendsLocalizer',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Retrouvez-vous, même sans réseau.',
                  style: TextStyle(color: p.textMuted, fontSize: 13)),
              const Spacer(),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Ton prénom',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: _continue, child: const Text('Commencer')),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

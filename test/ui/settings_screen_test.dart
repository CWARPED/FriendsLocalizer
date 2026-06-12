import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/screens/settings_screen.dart';
import 'package:friends_localizer/ui/theme.dart';

void main() {
  testWidgets('affiche l\'identité et l\'adresse serveur courante', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildLightTheme(), home: const SettingsScreen()),
    ));
    expect(find.text('Marie'), findsOneWidget);
    // L'URL par défaut du fake est pré-remplie dans le champ (EditableText).
    expect(find.text('ws://127.0.0.1:8080'), findsOneWidget);
  });

  testWidgets('modifier l\'adresse serveur met à jour les réglages', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildLightTheme(), home: const SettingsScreen()),
    ));
    await tester.enterText(
        find.byKey(const Key('serverUrlField')), 'ws://relay.example:9000');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(repo.settings.serverUrl, 'ws://relay.example:9000');
  });

  testWidgets('enregistre la position desktop', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(
        repository: repo,
        child: MaterialApp(theme: buildLightTheme(), home: const SettingsScreen())));
    await tester.enterText(find.byKey(const Key('myLatField')), '48.85');
    await tester.enterText(find.byKey(const Key('myLonField')), '2.35');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(repo.settings.myLat, closeTo(48.85, 1e-9));
    expect(repo.settings.myLon, closeTo(2.35, 1e-9));
  });
}

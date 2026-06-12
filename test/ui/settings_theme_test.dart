import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/models.dart';
import 'package:friends_localizer/ui/screens/settings_screen.dart';
import 'package:friends_localizer/ui/theme.dart';

void main() {
  testWidgets('choisir « Sombre » met themeMode = dark', (tester) async {
    // Surface suffisamment haute pour afficher le SegmentedButton sans défilement.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const SettingsScreen()),
    ));
    await tester.tap(find.text('Sombre'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(repo.settings.themeMode, AppThemeChoice.dark);
  });

  testWidgets('les sections Connexion et Thème sont présentes', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const SettingsScreen()),
    ));
    expect(find.text('CONNEXION'), findsOneWidget);
    expect(find.text('THÈME'), findsOneWidget);
  });
}

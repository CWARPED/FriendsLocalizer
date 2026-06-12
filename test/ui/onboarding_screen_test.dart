import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/screens/onboarding_screen.dart';

void main() {
  testWidgets('onboarding : logo, slogan, bouton Commencer, crée l\'identité',
      (tester) async {
    final repo = FakeRepository();
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const OnboardingScreen()),
    ));
    expect(find.byIcon(Icons.radar), findsOneWidget);
    expect(find.textContaining('Retrouvez-vous'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Marie');
    await tester.tap(find.text('Commencer'));
    await tester.pump();
    expect(repo.identity?.name, 'Marie');
  });

  testWidgets('onboarding : un prénom vide ne crée pas d\'identité',
      (tester) async {
    final repo = FakeRepository();
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const OnboardingScreen()),
    ));
    await tester.tap(find.text('Commencer'));
    await tester.pump();
    expect(repo.identity, isNull);
  });
}

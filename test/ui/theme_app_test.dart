import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/models.dart';

void main() {
  testWidgets('themeMode dark => thème sombre', (tester) async {
    final repo = FakeRepository();
    repo.updateSettings(const AppSettings(themeMode: AppThemeChoice.dark));
    await tester.pumpWidget(
        AppScope(repository: repo, child: const FriendsApp()));
    await tester.pump(); // un frame suffit ; éviter pumpAndSettle (curseur clignotant)
    final ctx = tester.element(find.byType(Gate));
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });

  testWidgets('themeMode light => thème clair', (tester) async {
    final repo = FakeRepository();
    repo.updateSettings(const AppSettings(themeMode: AppThemeChoice.light));
    await tester.pumpWidget(
        AppScope(repository: repo, child: const FriendsApp()));
    await tester.pump(); // un frame suffit ; éviter pumpAndSettle (curseur clignotant)
    final ctx = tester.element(find.byType(Gate));
    expect(Theme.of(ctx).brightness, Brightness.light);
  });
}

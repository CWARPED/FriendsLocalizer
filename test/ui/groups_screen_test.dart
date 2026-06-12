import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/widgets/app_card.dart';
import 'package:friends_localizer/ui/screens/groups_screen.dart';
import 'package:friends_localizer/ui/screens/group_detail_screen.dart';

void main() {
  testWidgets('accueil : groupes en cartes, ouverture du détail',
      (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await repo.createGroup('Festival');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const GroupsScreen()),
    ));
    expect(find.widgetWithText(AppCard, 'Festival'), findsOneWidget);
    await tester.tap(find.text('Festival'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupDetailScreen), findsOneWidget);
  });

  testWidgets('accueil : état vide affiche un message', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const GroupsScreen()),
    ));
    expect(find.textContaining('Aucun groupe'), findsOneWidget);
  });
}

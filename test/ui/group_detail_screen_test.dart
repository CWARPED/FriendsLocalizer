import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/screens/group_detail_screen.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/screens/invite_screen.dart';

void main() {
  testWidgets('affiche les membres et les actions de localisation', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(home: GroupDetailScreen(groupId: g.id)),
    ));
    expect(find.text('Tom'), findsOneWidget);
    expect(find.text('Localiser'), findsOneWidget);
  });

  testWidgets('le menu permet de voir l\'invitation', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(
          theme: buildDarkTheme(), home: GroupDetailScreen(groupId: g.id)),
    ));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir l\'invitation'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Copier le lien'), findsOneWidget);
  });

  testWidgets('quitter un groupe (avec confirmation) le retire', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => GroupDetailScreen(groupId: g.id)),
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitter le groupe'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Quitter'));
    await tester.pumpAndSettle();
    expect(repo.groups.any((x) => x.id == g.id), isFalse);
  });

  testWidgets('le bouton « Ajouter des membres » ouvre l\'invitation',
      (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(
          theme: buildDarkTheme(), home: GroupDetailScreen(groupId: g.id)),
    ));
    await tester.tap(find.text('Ajouter des membres'));
    await tester.pumpAndSettle();
    expect(find.byType(InviteScreen), findsOneWidget);
  });
}

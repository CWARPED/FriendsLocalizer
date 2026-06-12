import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/screens/join_group_screen.dart';

void main() {
  testWidgets('coller un lien valide rejoint le groupe', (tester) async {
    final creator = FakeRepository();
    await creator.createIdentity('Alice');
    final g = await creator.createGroup('Coloc');
    final link = 'fl://join#${creator.inviteFor(g.id)}';

    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const JoinGroupScreen()),
    ));
    await tester.enterText(find.byType(TextField), link);
    await tester.tap(find.text('Rejoindre'));
    await tester.pumpAndSettle();
    expect(repo.groups.isNotEmpty, isTrue);
  });

  testWidgets('un lien invalide affiche une erreur', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const JoinGroupScreen()),
    ));
    await tester.enterText(find.byType(TextField), 'n\'importe quoi');
    await tester.tap(find.text('Rejoindre'));
    await tester.pumpAndSettle();
    expect(find.textContaining('invalide'), findsOneWidget);
    expect(repo.groups, isEmpty);
  });

  testWidgets('sur desktop, le scan indique la caméra indisponible',
      (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const JoinGroupScreen()),
    ));
    // L'hôte de test (Windows) n'est pas Android/iOS -> scan désactivé.
    expect(find.textContaining('caméra indisponible'), findsOneWidget);
  });
}

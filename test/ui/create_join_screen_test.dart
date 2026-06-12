import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/screens/create_group_screen.dart';
import 'package:friends_localizer/ui/screens/join_group_screen.dart';

Widget _wrap(FakeRepository repo, Widget child) => AppScope(
    repository: repo,
    child: MaterialApp(theme: buildDarkTheme(), home: child));

void main() {
  testWidgets('créer un groupe : champ + bouton Créer', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(_wrap(repo, const CreateGroupScreen()));
    expect(find.text('Créer'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Coloc');
    await tester.tap(find.text('Créer'));
    await tester.pump();
    expect(repo.groups.any((g) => g.name == 'Coloc'), isTrue);
  });

  testWidgets('rejoindre : bloc scan + bouton Rejoindre', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(_wrap(repo, const JoinGroupScreen()));
    expect(find.text('Rejoindre'), findsOneWidget);
    expect(find.textContaining('Scanner'), findsOneWidget);
  });
}

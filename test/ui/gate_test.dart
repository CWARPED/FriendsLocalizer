import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';

void main() {
  testWidgets('sans identité, le Gate montre l\'onboarding', (tester) async {
    final repo = FakeRepository();
    await tester.pumpWidget(AppScope(repository: repo, child: const FriendsApp()));
    expect(find.text('Commencer'), findsOneWidget); // bouton de l'onboarding
  });

  testWidgets('avec identité, le Gate montre les groupes', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(repository: repo, child: const FriendsApp()));
    await tester.pumpAndSettle();
    expect(find.text('Mes groupes'), findsOneWidget);
  });
}

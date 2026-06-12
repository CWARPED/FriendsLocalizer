import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/screens/create_group_screen.dart';

void main() {
  testWidgets('créer un groupe affiche un QR et un lien', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: const CreateGroupScreen()),
    ));
    await tester.enterText(find.byType(TextField), 'Festival');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Copier le lien'), findsOneWidget);
    expect(repo.groups.any((g) => g.name == 'Festival'), isTrue);
  });
}

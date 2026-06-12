import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/screens/invite_screen.dart';

void main() {
  testWidgets('invite : QR, bouton Partager, copier (tooltip)', (tester) async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    await tester.pumpWidget(AppScope(
      repository: repo,
      child: MaterialApp(
          theme: buildDarkTheme(),
          home: InviteScreen(groupId: g.id, groupName: 'Festival')),
    ));
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('Partager'), findsOneWidget);
    expect(find.byTooltip('Copier le lien'), findsOneWidget);
  });
}

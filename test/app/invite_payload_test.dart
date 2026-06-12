import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/onboarding.dart';

void main() {
  test('extractInvitePayload : lien, payload nu, espaces', () {
    expect(extractInvitePayload('fl://join#ABC'), 'ABC');
    expect(extractInvitePayload('  ABC  '), 'ABC');
    expect(extractInvitePayload('ABC'), 'ABC');
  });

  test('tryDecodeInvite : valide -> invitation, invalide -> null', () {
    final payload = GroupInvite(
      groupId: 'g1',
      groupName: 'Festival',
      groupSecret: Uint8List(32),
      creatorName: 'Marie',
      creatorSignPublicKey: Uint8List(32),
    ).encode();
    expect(tryDecodeInvite(payload)?.groupName, 'Festival');
    expect(tryDecodeInvite('fl://join#$payload')?.groupName, 'Festival');
    expect(tryDecodeInvite('pas un qr'), isNull);
  });
}

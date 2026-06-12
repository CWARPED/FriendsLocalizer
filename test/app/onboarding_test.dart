import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/onboarding.dart';

void main() {
  test('GroupInvite encode/decode round-trip', () {
    final invite = GroupInvite(
      groupId: 'festival-2026',
      groupName: 'Festival 2026',
      groupSecret: Uint8List.fromList(List<int>.generate(32, (i) => i)),
      creatorName: 'Alice',
      creatorSignPublicKey: Uint8List.fromList(List<int>.generate(32, (i) => 255 - i)),
    );
    final s = invite.encode();
    final back = GroupInvite.decode(s);
    expect(back.groupId, 'festival-2026');
    expect(back.groupName, 'Festival 2026');
    expect(back.creatorName, 'Alice');
    expect(back.groupSecret, invite.groupSecret);
    expect(back.creatorSignPublicKey, invite.creatorSignPublicKey);
  });

  test('decode rejette un payload corrompu', () {
    expect(() => GroupInvite.decode('pas-du-base64-valide!!!'), throwsFormatException);
  });

  test('decode rejette un JSON valide mais sans les clés requises', () {
    // base64 d'un JSON valide {"v":1} qui n'a aucune des clés g/k/n/p.
    final payload = base64.encode(utf8.encode('{"v":1}'));
    expect(() => GroupInvite.decode(payload), throwsFormatException);
  });

  test('decode rejette une version inconnue', () {
    final payload = base64.encode(utf8.encode(json.encode({
      'v': 2, 'g': 'g', 'k': base64.encode(Uint8List(32)),
      'n': 'X', 'p': base64.encode(Uint8List(32)),
    })));
    expect(() => GroupInvite.decode(payload), throwsFormatException);
  });
}

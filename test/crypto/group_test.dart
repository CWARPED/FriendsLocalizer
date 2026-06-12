import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/group.dart';

void main() {
  test('crée un groupe avec Kg de 32 octets', () async {
    final g = await Group.create('festival-2026');
    expect(g.groupId, 'festival-2026');
    expect(g.groupSecret.length, 32);
  });

  test('dérive une clé de chiffrement déterministe de 32 octets', () async {
    final secret = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final g = Group('g1', secret, const []);
    final k1 = await g.encryptionKey();
    final k2 = await g.encryptionKey();
    expect(k1.length, 32);
    expect(k1, k2); // déterministe
  });

  test('isMember reconnaît une clé publique du roster', () {
    final pub = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    final g = Group('g1', Uint8List(32), [Member('Alice', pub)]);
    expect(g.isMember(pub), isTrue);
    expect(g.isMember(Uint8List(32)), isFalse);
  });
}

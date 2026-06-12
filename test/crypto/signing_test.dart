import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/identity.dart';
import 'package:friends_localizer/crypto/signing.dart';

void main() {
  test('signe et vérifie avec la bonne clé publique', () async {
    final id = await Identity.generate();
    final msg = Uint8List.fromList([1, 2, 3, 4]);
    final sig = await Signing.sign(msg, id);
    final ok = await Signing.verify(msg, sig, id.signPublicKey);
    expect(ok, isTrue);
  });

  test('rejette une signature pour un message altéré', () async {
    final id = await Identity.generate();
    final msg = Uint8List.fromList([1, 2, 3, 4]);
    final sig = await Signing.sign(msg, id);
    final tampered = Uint8List.fromList([9, 9, 9, 9]);
    final ok = await Signing.verify(tampered, sig, id.signPublicKey);
    expect(ok, isFalse);
  });

  test('rejette une signature d\'une autre identité', () async {
    final a = await Identity.generate();
    final b = await Identity.generate();
    final msg = Uint8List.fromList([1, 2, 3, 4]);
    final sig = await Signing.sign(msg, a);
    final ok = await Signing.verify(msg, sig, b.signPublicKey);
    expect(ok, isFalse);
  });

  test('renvoie false sur une signature malformée (mauvaise longueur)', () async {
    final id = await Identity.generate();
    final msg = Uint8List.fromList([1, 2, 3, 4]);
    final malformed = Uint8List.fromList([1, 2, 3]); // pas 64 octets
    final ok = await Signing.verify(msg, malformed, id.signPublicKey);
    expect(ok, isFalse);
  });
}

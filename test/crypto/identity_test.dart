import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/identity.dart';

void main() {
  test('génère une identité avec clés Ed25519 et X25519', () async {
    final id = await Identity.generate();
    expect(id.signPublicKey.length, 32);
    expect(id.exchangePublicKey.length, 32);
  });

  test('sérialise et redonne la même identité', () async {
    final id = await Identity.generate();
    final bytes = id.toBytes();
    expect(bytes.length, 64);
    final restored = await Identity.fromBytes(bytes);
    expect(restored.signPublicKey, id.signPublicKey);
    expect(restored.exchangePublicKey, id.exchangePublicKey);
  });

  test('fromBytes rejette une longueur incorrecte', () async {
    expect(() => Identity.fromBytes(Uint8List(32)), throwsArgumentError);
  });
}

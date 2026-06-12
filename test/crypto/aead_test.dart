import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/aead.dart';

void main() {
  final key = Uint8List.fromList(List<int>.generate(32, (i) => i));

  test('chiffre puis déchiffre redonne le clair', () async {
    final clear = Uint8List.fromList([10, 20, 30, 40, 50]);
    final box = await Aead.encrypt(clear, key);
    final back = await Aead.decrypt(box, key);
    expect(back, clear);
  });

  test('déchiffrer avec une mauvaise clé échoue', () async {
    final clear = Uint8List.fromList([10, 20, 30]);
    final box = await Aead.encrypt(clear, key);
    final wrong = Uint8List.fromList(List<int>.generate(32, (i) => 255 - i));
    expect(() => Aead.decrypt(box, wrong), throwsA(anything));
  });

  test('deux chiffrements du même clair donnent des sorties différentes (nonce aléatoire)', () async {
    final clear = Uint8List.fromList([1, 2, 3]);
    final a = await Aead.encrypt(clear, key);
    final b = await Aead.encrypt(clear, key);
    expect(a, isNot(equals(b)));
  });
}

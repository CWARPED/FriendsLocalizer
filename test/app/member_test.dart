import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/member.dart';

void main() {
  test('memberId est un hex de 64 caractères pour une clé de 32 octets', () {
    final pub = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final id = memberId(pub);
    expect(id.length, 64);
    expect(id.startsWith('000102'), isTrue);
  });

  test('deux clés différentes donnent des id différents', () {
    final a = memberId(Uint8List.fromList(List<int>.generate(32, (i) => i)));
    final b = memberId(Uint8List.fromList(List<int>.generate(32, (i) => i + 1)));
    expect(a, isNot(equals(b)));
  });

  test('la cible « tout le groupe » est une constante', () {
    expect(kAllMembers, '*');
  });
}

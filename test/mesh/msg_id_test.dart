import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/mesh/msg_id.dart';

void main() {
  test('génère 16 octets', () {
    final m = generateMsgId(Random(1));
    expect(m.length, 16);
  });

  test('deux appels successifs diffèrent', () {
    final r = Random(1);
    final a = generateMsgId(r);
    final b = generateMsgId(r);
    expect(a, isNot(equals(b)));
  });

  test('déterministe pour une même graine', () {
    final a = generateMsgId(Random(42));
    final b = generateMsgId(Random(42));
    expect(a, equals(b));
  });
}

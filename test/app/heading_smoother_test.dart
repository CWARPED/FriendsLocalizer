import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/heading.dart';

void main() {
  test('normalizeDegrees ramène dans [0,360)', () {
    expect(normalizeDegrees(370), 10);
    expect(normalizeDegrees(-10), 350);
    expect(normalizeDegrees(0), 0);
  });

  test('shortestDelta prend le plus court arc (passage 0)', () {
    expect(shortestDelta(350, 10), 20);
    expect(shortestDelta(10, 350), -20);
    expect(shortestDelta(0, 180), 180);
  });

  test('1re valeur prise telle quelle ; lissage ne traverse pas par 180', () {
    final s = HeadingSmoother(alpha: 0.5);
    expect(s.add(350), 350);
    expect(s.add(10), closeTo(0, 0.001)); // 350 + 0.5*20 = 360 -> 0
  });

  test('le lissage est une moyenne pondérée', () {
    final s = HeadingSmoother(alpha: 0.5);
    s.add(0);
    expect(s.add(100), closeTo(50, 0.001));
    expect(s.value, closeTo(50, 0.001));
  });
}

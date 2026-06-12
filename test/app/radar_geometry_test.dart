import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/geo.dart';
import 'package:friends_localizer/app/radar.dart';

void main() {
  test('radarRadiusFraction : 0/50/500/au-delà', () {
    expect(radarRadiusFraction(0), 0);
    expect(radarRadiusFraction(25), closeTo(0.25, 1e-9));
    expect(radarRadiusFraction(50), closeTo(0.5, 1e-9));
    expect(radarRadiusFraction(500), closeTo(1.0, 1e-9));
    expect(radarRadiusFraction(1000), 1.0);
  });

  test('radarAngleDegrees : cap relatif', () {
    const me = GeoPoint(0, 0);
    const north = GeoPoint(1, 0); // plein nord -> bearing 0
    expect(radarAngleDegrees(me, north, 0), closeTo(0, 1e-6));
    expect(radarAngleDegrees(me, north, 90), closeTo(270, 1e-6));
  });

  test('radarOffset : 0° = haut, 90° = droite', () {
    final up = radarOffset(0, 1, 200);
    expect(up.dx, closeTo(100, 1e-9));
    expect(up.dy, closeTo(100 - (100 - kRadarEdgeMargin), 1e-9));
    final right = radarOffset(90, 1, 200);
    expect(right.dx, closeTo(100 + (100 - kRadarEdgeMargin), 1e-9));
    expect(right.dy, closeTo(100, 1e-9));
  });
}

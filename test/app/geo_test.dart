import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/geo.dart';

void main() {
  test('distance Paris-Lille (~204 km)', () {
    const paris = GeoPoint(48.8566, 2.3522);
    const lille = GeoPoint(50.6292, 3.0573);
    final d = distanceMeters(paris, lille);
    expect(d, closeTo(204000, 5000));
  });

  test('distance nulle pour le même point', () {
    const p = GeoPoint(48.0, 2.0);
    expect(distanceMeters(p, p), closeTo(0, 0.001));
  });

  test('cap vers l\'est ~ 90°', () {
    const a = GeoPoint(0, 0);
    const b = GeoPoint(0, 1);
    expect(initialBearingDegrees(a, b), closeTo(90, 0.5));
  });

  test('cap vers le nord ~ 0°', () {
    const a = GeoPoint(0, 0);
    const b = GeoPoint(1, 0);
    expect(initialBearingDegrees(a, b), closeTo(0, 0.5));
  });

  test('le cap est normalisé dans [0,360)', () {
    const a = GeoPoint(0, 0);
    const b = GeoPoint(-1, 0);
    final brg = initialBearingDegrees(a, b);
    expect(brg, inInclusiveRange(0, 360));
    expect(brg, closeTo(180, 0.5));
  });
}

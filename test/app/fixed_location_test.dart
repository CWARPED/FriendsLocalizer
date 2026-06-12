import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/geo.dart';
import 'package:friends_localizer/app/fixed_location.dart';

void main() {
  test('renvoie la position fixe fournie', () async {
    final p = FixedLocationProvider(const GeoPoint(48.85, 2.35), accuracyMeters: 7);
    final fix = await p.current();
    expect(fix.point.latitude, 48.85);
    expect(fix.point.longitude, 2.35);
    expect(fix.accuracyMeters, 7);
  });
}

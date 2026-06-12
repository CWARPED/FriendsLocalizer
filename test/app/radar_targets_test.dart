import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/geo.dart';
import 'package:friends_localizer/app/location_service.dart';
import 'package:friends_localizer/app/radar.dart';

void main() {
  test('buildRadarTargets : un membre situé à l\'est, un sans position', () {
    const me = GeoPoint(0, 0);
    final east = LocatedPosition('tom', const GeoPoint(0, 0.001), 5, 100000);
    final inputs = [
      RadarInput('tom', 'Tom', east),
      RadarInput('lea', 'Léa', null), // pas de position -> omise
    ];
    final targets = buildRadarTargets(
        me: me, headingDegrees: 0, inputs: inputs, nowMs: 108000);
    expect(targets.length, 1);
    expect(targets.first.memberId, 'tom');
    expect(targets.first.angleDegrees, closeTo(90, 0.5)); // est
    expect(targets.first.distanceMeters, greaterThan(0));
    expect(targets.first.freshnessSeconds, 8); // (108000-100000)/1000
  });
}

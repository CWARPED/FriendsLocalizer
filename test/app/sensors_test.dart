import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/geo.dart';
import 'package:friends_localizer/app/heading.dart';
import 'package:friends_localizer/app/sensors.dart';

class FakeLocation implements LocationProvider {
  final GeoPoint point;
  final double accuracy;
  FakeLocation(this.point, {this.accuracy = 5});
  @override
  Future<LocationFix> current() async => LocationFix(point, accuracy);
}

class FakeHeading implements HeadingProvider {
  final double deg;
  FakeHeading(this.deg);
  @override
  Stream<HeadingReading> readings() => Stream.value(HeadingReading(deg));
}

void main() {
  test('LocationProvider fournit une position et une précision', () async {
    final loc = FakeLocation(const GeoPoint(48, 2), accuracy: 8);
    final fix = await loc.current();
    expect(fix.point.latitude, 48);
    expect(fix.accuracyMeters, 8);
  });

  test('HeadingProvider émet un cap', () async {
    final h = FakeHeading(123);
    expect((await h.readings().first).degrees, 123);
  });
}

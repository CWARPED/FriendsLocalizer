import 'geo.dart';
import 'sensors.dart';

/// Position fixe (desktop sans GPS, tests). Modifiable via [point].
class FixedLocationProvider implements LocationProvider {
  GeoPoint point;
  double accuracyMeters;
  FixedLocationProvider(this.point, {this.accuracyMeters = 5});

  @override
  Future<LocationFix> current() async => LocationFix(point, accuracyMeters);
}

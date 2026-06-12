import 'dart:math' as math;

/// Un point géographique (degrés décimaux).
class GeoPoint {
  final double latitude;
  final double longitude;
  const GeoPoint(this.latitude, this.longitude);
}

const double _earthRadiusM = 6371000.0;

double _deg2rad(double d) => d * math.pi / 180.0;
double _rad2deg(double r) => r * 180.0 / math.pi;

/// Distance en mètres entre [a] et [b] (formule de haversine).
double distanceMeters(GeoPoint a, GeoPoint b) {
  final dLat = _deg2rad(b.latitude - a.latitude);
  final dLon = _deg2rad(b.longitude - a.longitude);
  final lat1 = _deg2rad(a.latitude);
  final lat2 = _deg2rad(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return _earthRadiusM * c;
}

/// Cap initial (degrés, 0 = nord, sens horaire) de [a] vers [b], dans [0,360).
double initialBearingDegrees(GeoPoint a, GeoPoint b) {
  final lat1 = _deg2rad(a.latitude);
  final lat2 = _deg2rad(b.latitude);
  final dLon = _deg2rad(b.longitude - a.longitude);
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  final brg = _rad2deg(math.atan2(y, x));
  return (brg + 360.0) % 360.0;
}

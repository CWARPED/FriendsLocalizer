import 'geo.dart';
import 'heading.dart';

/// Une mesure de position avec sa précision.
class LocationFix {
  final GeoPoint point;
  final double accuracyMeters;
  const LocationFix(this.point, this.accuracyMeters);
}

/// Source de position GPS (abstraite : adaptateur réel = device).
///
/// `current()` peut renvoyer `null` quand aucune position fiable n'est
/// disponible (GPS coupé, permission refusée) : dans ce cas l'appli ne répond
/// pas à une demande de localisation plutôt que d'inventer une position.
abstract class LocationProvider {
  Future<LocationFix?> current();
}

/// Source de cap (boussole). Émet des mesures lissées et qualifiées.
abstract class HeadingProvider {
  Stream<HeadingReading> readings();
}

import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'geo.dart';
import 'fixed_location.dart';
import 'sensors.dart';

/// Provider réel basé sur le GPS de l'appareil.
///
/// ADAPTATEUR DEVICE : non testé unitairement (plugin natif). N'est instancié
/// que sur mobile via [defaultLocationProvider]. Renvoie `null` (donc pas de
/// réponse à une demande de localisation) si la permission est refusée, le
/// service coupé, ou en cas d'erreur — on ne fabrique jamais de position.
class GeolocatorLocationProvider implements LocationProvider {
  @override
  Future<LocationFix?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      try {
        // Borne l'attente : en intérieur/foule le fix peut tarder.
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 8)),
        );
        return LocationFix(GeoPoint(pos.latitude, pos.longitude), pos.accuracy);
      } catch (_) {
        // GPS lent/indisponible : repli sur la dernière position connue plutôt
        // que de rester muet (on renvoie quelque chose, même un peu ancien).
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          return LocationFix(
              GeoPoint(last.latitude, last.longitude), last.accuracy);
        }
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Flux de positions GPS : émet une nouvelle mesure à chaque déplacement
  /// (filtre de 2 m). Sert à rafraîchir le centre du radar pendant qu'on reste
  /// sur l'écran Localiser. Les erreurs (permission/serveur coupé) sont ignorées.
  Stream<LocationFix> stream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 2),
    )
        .map((p) => LocationFix(GeoPoint(p.latitude, p.longitude), p.accuracy))
        .handleError((Object _) {});
  }
}

/// Choisit le provider de position selon la plateforme :
/// mobile (Android/iOS) → GPS réel ; ailleurs (desktop/émulateur/test) →
/// position manuelle [manualFallback] (coordonnées saisies dans les réglages).
LocationProvider defaultLocationProvider({GeoPoint? manualFallback}) {
  if (Platform.isAndroid || Platform.isIOS) {
    return GeolocatorLocationProvider();
  }
  return FixedLocationProvider(manualFallback ?? const GeoPoint(0, 0));
}

import 'dart:io';
import 'package:flutter_compass/flutter_compass.dart';
import 'heading.dart';
import 'heading_providers.dart';
import 'sensors.dart';

/// Provider réel basé sur la boussole de l'appareil (magnétomètre), lissé.
///
/// ADAPTATEUR DEVICE : non testé unitairement (plugin natif). N'est instancié
/// que sur mobile via [defaultHeadingProvider]. La boussole ne nécessite aucune
/// permission runtime (capteur, pas la localisation).
class CompassHeadingProvider implements HeadingProvider {
  final HeadingSmoother _smoother;

  CompassHeadingProvider({double alpha = 0.25})
      : _smoother = HeadingSmoother(alpha: alpha);

  /// À appeler une seule fois par instance : le lisseur est à état, des
  /// abonnements multiples partageraient (et corrompraient) ce state.
  @override
  Stream<HeadingReading> readings() {
    final events = FlutterCompass.events ?? const Stream<CompassEvent>.empty();
    return events.where((e) => e.heading != null).map(
          (e) => HeadingReading(
            _smoother.add(e.heading!),
            accuracyDegrees: e.accuracy,
          ),
        );
  }
}

/// Choisit le provider de cap selon la plateforme :
/// mobile (Android/iOS) → boussole réelle ; ailleurs (desktop/émulateur/test)
/// → aucun cap (le radar du Plan C basculera en repli nord-en-haut).
HeadingProvider defaultHeadingProvider() {
  if (Platform.isAndroid || Platform.isIOS) {
    return CompassHeadingProvider();
  }
  return const NullHeadingProvider();
}

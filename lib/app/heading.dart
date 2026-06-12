/// Niveau de confiance dans le cap renvoyé par la boussole.
enum HeadingReliability { good, low, unknown }

/// Seuil de précision (degrés) en-deçà duquel le cap est jugé fiable (spec §3).
const double kHeadingGoodAccuracyDegrees = 20;

/// Classe la fiabilité d'un cap à partir de la précision (en degrés) annoncée
/// par le capteur. `null` ou valeur négative = inconnue (capteur muet / non
/// calibré → on invitera l'utilisateur à calibrer).
HeadingReliability reliabilityFor(double? accuracyDegrees) {
  if (accuracyDegrees == null || accuracyDegrees < 0) {
    return HeadingReliability.unknown;
  }
  return accuracyDegrees <= kHeadingGoodAccuracyDegrees
      ? HeadingReliability.good
      : HeadingReliability.low;
}

/// Une mesure de cap : direction magnétique + marge d'erreur annoncée.
class HeadingReading {
  /// Cap magnétique normalisé dans [0, 360).
  final double degrees;

  /// Marge d'erreur en degrés annoncée par le capteur (`null` = inconnue).
  final double? accuracyDegrees;

  const HeadingReading(this.degrees, {this.accuracyDegrees});

  HeadingReliability get reliability => reliabilityFor(accuracyDegrees);
}

/// Ramène un angle dans [0, 360).
double normalizeDegrees(double d) {
  final m = d % 360;
  return m < 0 ? m + 360 : m;
}

/// Plus court écart angulaire de [from] vers [to], dans [-180, 180].
double shortestDelta(double from, double to) {
  var diff = normalizeDegrees(to - from);
  // À exactement 180°, la garde stricte (> 180) conserve +180 : sens horaire choisi.
  if (diff > 180) diff -= 360;
  return diff;
}

/// Lissage exponentiel d'un cap, robuste au passage 359°→0°.
/// [alpha] dans [0, 1] : plus grand = plus réactif, plus petit = plus lisse.
class HeadingSmoother {
  final double alpha;
  double? _value;

  HeadingSmoother({this.alpha = 0.25});

  /// Dernière valeur lissée (null tant qu'aucune mesure n'a été fournie).
  double? get value => _value;

  /// Intègre une nouvelle mesure brute et renvoie le cap lissé.
  double add(double degrees) {
    final target = normalizeDegrees(degrees);
    final current = _value;
    if (current == null) {
      _value = target;
    } else {
      _value = normalizeDegrees(current + alpha * shortestDelta(current, target));
    }
    return _value!;
  }
}

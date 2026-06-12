import 'dart:math' as math;
import 'geo.dart';
import 'heading.dart';
import 'location_service.dart' show LocatedPosition;

/// Durée d'une session de suivi en direct (5 minutes).
const int kSessionDurationMs = 5 * 60 * 1000;

/// Marge (px) entre le bord du cadran et le rayon utile des points.
const double kRadarEdgeMargin = 14;

/// Rayon normalisé [0,1] (0 = centre, 1 = bord) pour une distance, avec anneaux
/// de référence à 50 m (mi-rayon) et 500 m (bord). Au-delà de 500 m : épinglé.
double radarRadiusFraction(double meters) {
  if (meters <= 0) return 0;
  if (meters <= 50) return (meters / 50) * 0.5;
  if (meters <= 500) return 0.5 + (meters - 50) / 450 * 0.5;
  return 1.0;
}

/// Angle d'affichage (degrés, 0 = haut, sens horaire) d'une cible : cap
/// géographique vers elle moins le cap de l'appareil (cap-en-haut). En repli
/// nord-en-haut, passer [headingDegrees] = 0.
double radarAngleDegrees(GeoPoint me, GeoPoint target, double headingDegrees) {
  return normalizeDegrees(initialBearingDegrees(me, target) - headingDegrees);
}

/// Position en pixels d'une cible dans un carré de côté [size] (origine
/// haut-gauche), pour [angleDegrees] (0 = haut, horaire) et [radiusFraction].
({double dx, double dy}) radarOffset(
    double angleDegrees, double radiusFraction, double size) {
  final c = size / 2;
  final r = radiusFraction * (c - kRadarEdgeMargin);
  final a = angleDegrees * math.pi / 180.0;
  return (dx: c + r * math.sin(a), dy: c - r * math.cos(a));
}

/// Une cible prête à dessiner sur le radar.
class RadarTarget {
  final String memberId;
  final String name;
  final double angleDegrees;   // 0 = haut, horaire
  final double radiusFraction; // 0..1
  final double distanceMeters;
  final int freshnessSeconds;
  const RadarTarget({
    required this.memberId,
    required this.name,
    required this.angleDegrees,
    required this.radiusFraction,
    required this.distanceMeters,
    required this.freshnessSeconds,
  });
}

/// Entrée d'assemblage : un membre et sa dernière position connue (ou null).
class RadarInput {
  final String memberId;
  final String name;
  final LocatedPosition? fix;
  const RadarInput(this.memberId, this.name, this.fix);
}

/// Construit une [RadarTarget] par membre AYANT une position. Les membres sans
/// position sont omis (affichés "en attente" dans la liste, pas sur le radar).
List<RadarTarget> buildRadarTargets({
  required GeoPoint me,
  required double headingDegrees,
  required List<RadarInput> inputs,
  required int nowMs,
}) {
  final out = <RadarTarget>[];
  for (final i in inputs) {
    final fix = i.fix;
    if (fix == null) continue;
    final d = distanceMeters(me, fix.point);
    final fresh = ((nowMs - fix.timestampMs) / 1000).floor();
    out.add(RadarTarget(
      memberId: i.memberId,
      name: i.name,
      angleDegrees: radarAngleDegrees(me, fix.point, headingDegrees),
      radiusFraction: radarRadiusFraction(d),
      distanceMeters: d,
      freshnessSeconds: fresh < 0 ? 0 : fresh,
    ));
  }
  return out;
}

/// Secondes restantes d'une session se terminant à [endMs] à l'instant [nowMs]
/// (jamais négatif).
int sessionRemainingSeconds(int endMs, int nowMs) {
  final r = ((endMs - nowMs) / 1000).ceil();
  return r < 0 ? 0 : r;
}

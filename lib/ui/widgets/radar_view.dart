import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/radar.dart';
import '../friend_colors.dart';
import '../theme.dart';

/// Cadran radar sobre : toi au centre, anneaux 50 m / 500 m, un point coloré
/// par ami (angle = direction, rayon = distance).
class RadarView extends StatelessWidget {
  final List<RadarTarget> targets;

  /// Cap de l'appareil (degrés). Sert à placer le repère « N » : en cap-en-haut,
  /// le nord se trouve à l'angle `-cap` et tourne quand on pivote le téléphone.
  /// 0 en repli nord-en-haut (le « N » reste alors en haut).
  final double headingDegrees;

  const RadarView({
    super.key,
    required this.targets,
    this.headingDegrees = 0,
  });

  /// Distance lisible (ex. "120 m", "1.3 km").
  static String formatDistance(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, constraints.maxHeight);
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Positioned.fill(
                    child: CustomPaint(
                        painter: _RadarBackdrop(p, headingDegrees))),
                Positioned.fill(child: CustomPaint(painter: _RadarLines(targets))),
                for (final t in targets) ..._dotWidgets(t, size),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _dotWidgets(RadarTarget t, double size) {
    final o = radarOffset(t.angleDegrees, t.radiusFraction, size);
    final color = colorForMember(t.memberId);
    return [
      Positioned(
        left: o.dx - 7,
        top: o.dy - 7,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
      Positioned(
        left: o.dx - 48,
        top: o.dy + 9,
        width: 96,
        // Nom et distance sur deux lignes distinctes : la distance s'affiche
        // toujours ; seul un nom très long est abrégé par « … ».
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
            Text(
              formatDistance(t.distanceMeters),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(color: color, fontSize: 10, height: 1.1),
            ),
          ],
        ),
      ),
    ];
  }
}

class _RadarBackdrop extends CustomPainter {
  final AppPalette p;
  final double headingDegrees;
  _RadarBackdrop(this.p, this.headingDegrees);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rMax = size.width / 2 - 2;
    canvas.drawCircle(c, rMax, Paint()..color = p.radarFace);
    final ring = Paint()
      ..color = p.radarRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(c, rMax, ring); // anneau ~500 m (bord)
    canvas.drawCircle(c, rMax * 0.5, ring); // anneau ~50 m
    canvas.drawCircle(
        c,
        rMax,
        Paint()
          ..color = p.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // repère "N" : placé au cap géographique du nord (0) en cap-en-haut, donc à
    // l'angle -cap. Il tourne autour du cadran quand on pivote le téléphone.
    final n = radarOffset(-headingDegrees, 1.0, size.width);
    final tp = TextPainter(
      text: TextSpan(
          text: 'N', style: TextStyle(color: p.textMuted, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(n.dx - tp.width / 2, n.dy - tp.height / 2));
    canvas.drawCircle(c, 4, Paint()..color = p.radarMark); // toi, au centre
  }

  @override
  bool shouldRepaint(covariant _RadarBackdrop old) =>
      !identical(old.p, p) || old.headingDegrees != headingDegrees;
}

/// Fins traits de rappel du centre vers chaque ami (couleur de l'ami, atténuée).
class _RadarLines extends CustomPainter {
  final List<RadarTarget> targets;
  _RadarLines(this.targets);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (final t in targets) {
      final o = radarOffset(t.angleDegrees, t.radiusFraction, size.width);
      final paint = Paint()
        ..color = colorForMember(t.memberId).withValues(alpha: 0.3)
        ..strokeWidth = 1.5;
      canvas.drawLine(c, Offset(o.dx, o.dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarLines old) => true;
}

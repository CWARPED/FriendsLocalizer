import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/radar.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/widgets/radar_view.dart';

void main() {
  testWidgets('RadarView affiche un libellé par cible', (tester) async {
    const targets = [
      RadarTarget(
          memberId: 'tom',
          name: 'Tom',
          angleDegrees: 40,
          radiusFraction: 0.6,
          distanceMeters: 120,
          freshnessSeconds: 3),
    ];
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: const Scaffold(body: RadarView(targets: targets)),
    ));
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.textContaining('Tom'), findsOneWidget);
    expect(find.textContaining('120 m'), findsOneWidget);
  });

  testWidgets('RadarView sans cible ne plante pas', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: const Scaffold(body: RadarView(targets: [])),
    ));
    expect(find.byType(RadarView), findsOneWidget);
  });
}

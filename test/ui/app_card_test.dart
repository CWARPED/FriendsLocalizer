import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/widgets/app_card.dart';

void main() {
  testWidgets('AppCard affiche son enfant', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: const Scaffold(body: AppCard(child: Text('coucou'))),
    ));
    expect(find.text('coucou'), findsOneWidget);
  });

  testWidgets('SectionLabel met en majuscules', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: const Scaffold(body: SectionLabel('connexion')),
    ));
    expect(find.text('CONNEXION'), findsOneWidget);
  });

  testWidgets('AppCard onTap déclenche', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: buildDarkTheme(),
      home: Scaffold(
          body: AppCard(onTap: () => tapped = true, child: const Text('x'))),
    ));
    await tester.tap(find.text('x'));
    expect(tapped, isTrue);
  });
}

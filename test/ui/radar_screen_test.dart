import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/heading.dart';
import 'package:friends_localizer/app/heading_providers.dart';
import 'package:friends_localizer/app/sensors.dart';
import 'package:friends_localizer/ui/app_scope.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/ui/theme.dart';
import 'package:friends_localizer/ui/screens/radar_screen.dart';

class _LowHeading implements HeadingProvider {
  @override
  Stream<HeadingReading> readings() =>
      Stream.value(const HeadingReading(0, accuracyDegrees: 45));
}

class _UnknownHeading implements HeadingProvider {
  @override
  Stream<HeadingReading> readings() => Stream.value(const HeadingReading(123));
}

Future<FakeRepository> _repoWithGroup() async {
  final repo = FakeRepository();
  await repo.createIdentity('Marie');
  await repo.createGroup('Festival'); // id g0, membres Marie+tom00+ana00
  return repo;
}

Widget _wrap(FakeRepository repo, Widget child) => AppScope(
      repository: repo,
      child: MaterialApp(theme: buildDarkTheme(), home: child),
    );

void main() {
  testWidgets('sans boussole -> note "indisponible"', (tester) async {
    final repo = await _repoWithGroup();
    await tester.pumpWidget(_wrap(
        repo,
        const RadarScreen(
            groupId: 'g0',
            groupName: 'Festival',
            headingProvider: NullHeadingProvider())));
    await tester.pump();
    expect(find.textContaining('Boussole indisponible'), findsOneWidget);
  });

  testWidgets('boussole peu fiable -> note calibration', (tester) async {
    final repo = await _repoWithGroup();
    await tester.pumpWidget(_wrap(
        repo,
        RadarScreen(
            groupId: 'g0',
            groupName: 'Festival',
            headingProvider: _LowHeading())));
    await tester.pump();
    expect(find.textContaining('calibre'), findsOneWidget);
  });

  testWidgets('boussole non calibrée (unknown) -> note calibration',
      (tester) async {
    final repo = await _repoWithGroup();
    await tester.pumpWidget(_wrap(
        repo,
        RadarScreen(
            groupId: 'g0',
            groupName: 'Festival',
            headingProvider: _UnknownHeading())));
    await tester.pump();
    expect(find.textContaining('calibre'), findsOneWidget);
  });

  testWidgets('momentané -> les amis apparaissent sur le radar', (tester) async {
    final repo = await _repoWithGroup();
    await tester.pumpWidget(_wrap(
        repo,
        const RadarScreen(
            groupId: 'g0',
            groupName: 'Festival',
            headingProvider: NullHeadingProvider())));
    await tester.pump();
    await tester.tap(find.byTooltip('Localisation momentanée'));
    await tester.pump();
    expect(find.textContaining('Tom'), findsWidgets);
  });

  testWidgets('décocher un ami retire son point du radar', (tester) async {
    final repo = await _repoWithGroup();
    await tester.pumpWidget(_wrap(
        repo,
        const RadarScreen(
            groupId: 'g0',
            groupName: 'Festival',
            headingProvider: NullHeadingProvider())));
    await tester.pump();
    await tester.tap(find.byTooltip('Localisation momentanée'));
    await tester.pump();
    // Tom apparaît 2 fois : libellé du radar + ligne de la liste.
    expect(find.textContaining('Tom'), findsNWidgets(2));
    // Décocher Tom dans la liste.
    final tomCheckbox = find.descendant(
        of: find.widgetWithText(ListTile, 'Tom'),
        matching: find.byType(Checkbox));
    await tester.tap(tomCheckbox);
    await tester.pump();
    // Plus que la ligne de liste (le point du radar a disparu).
    expect(find.textContaining('Tom'), findsOneWidget);
  });

  testWidgets('session 5 min affiche un décompte', (tester) async {
    final repo = await _repoWithGroup();
    await tester.pumpWidget(_wrap(
        repo,
        const RadarScreen(
            groupId: 'g0',
            groupName: 'Festival',
            headingProvider: NullHeadingProvider())));
    await tester.pump();
    await tester.tap(find.byTooltip('Session 5 min'));
    await tester.pump();
    expect(find.text('5:00'), findsOneWidget);
    // Démonte l'écran pour annuler le Timer périodique (évite "pending timer").
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('on ne se voit pas soi-même', (tester) async {
    final repo = await _repoWithGroup(); // identité = Marie
    await tester.pumpWidget(_wrap(
        repo,
        const RadarScreen(
            groupId: 'g0',
            groupName: 'Festival',
            headingProvider: NullHeadingProvider())));
    await tester.pump();
    expect(find.text('Marie'), findsNothing); // soi-même exclu
    expect(find.text('Tom'), findsOneWidget);
  });
}

import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/identity.dart';
import 'package:friends_localizer/crypto/group.dart';
import 'package:friends_localizer/app/geo.dart';
import 'package:friends_localizer/app/sensors.dart';
import 'package:friends_localizer/app/member.dart';
import 'package:friends_localizer/app/location_service.dart';

class FakeLocation implements LocationProvider {
  final GeoPoint point;
  FakeLocation(this.point);
  @override
  Future<LocationFix> current() async => LocationFix(point, 5);
}

/// Provider sans position fiable (GPS indisponible / permission refusée).
class NullLocation implements LocationProvider {
  @override
  Future<LocationFix?> current() async => null;
}

Future<void> _settle([int turns = 20]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('A localise B : demande -> B fixe son GPS -> A reçoit la position', () async {
    final idA = await Identity.generate();
    final idB = await Identity.generate();
    final aId = memberId(idA.signPublicKey);
    final bId = memberId(idB.signPublicKey);
    final kg = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final group = Group('g1', kg,
        [Member('A', idA.signPublicKey), Member('B', idB.signPublicKey)]);

    late LocationService a;
    late LocationService b;
    a = LocationService(
      identity: idA, myId: aId, groups: [group],
      location: FakeLocation(const GeoPoint(0, 0)),
      random: Random(1), nowMs: () => 1000,
      broadcast: (f) => b.handleIncoming(f),
    );
    b = LocationService(
      identity: idB, myId: bId, groups: [group],
      location: FakeLocation(const GeoPoint(48.0, 2.0)),
      random: Random(2), nowMs: () => 1000,
      broadcast: (f) => a.handleIncoming(f),
    );

    LocatedPosition? got;
    a.onLocated = (p) => got = p;
    await a.requestLocation(groupId: 'g1', targetId: bId);
    await _settle();

    expect(got, isNotNull);
    expect(got!.responderId, bId);
    expect(got!.point.latitude, closeTo(48.0, 1e-9));
    expect(got!.point.longitude, closeTo(2.0, 1e-9));
  });

  test('B sans fix GPS ne diffuse aucune réponse', () async {
    final idA = await Identity.generate();
    final idB = await Identity.generate();
    final aId = memberId(idA.signPublicKey);
    final bId = memberId(idB.signPublicKey);
    final kg = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final group = Group('g1', kg,
        [Member('A', idA.signPublicKey), Member('B', idB.signPublicKey)]);

    final bOut = <Uint8List>[];
    late LocationService a;
    late LocationService b;
    a = LocationService(
      identity: idA, myId: aId, groups: [group],
      location: FakeLocation(const GeoPoint(0, 0)),
      random: Random(1), nowMs: () => 1000,
      broadcast: (f) => b.handleIncoming(f),
    );
    b = LocationService(
      identity: idB, myId: bId, groups: [group],
      location: NullLocation(), // pas de GPS -> doit rester muet
      random: Random(2), nowMs: () => 1000,
      broadcast: (f) { bOut.add(f); a.handleIncoming(f); },
    );

    LocatedPosition? got;
    a.onLocated = (p) => got = p;
    await a.requestLocation(groupId: 'g1', targetId: bId);
    await _settle();

    expect(bOut, isEmpty); // B n'a rien diffusé
    expect(got, isNull); // A n'a donc rien reçu
  });

  test('un non-membre ne peut pas déchiffrer / répondre', () async {
    final idA = await Identity.generate();
    final idStranger = await Identity.generate();
    final aId = memberId(idA.signPublicKey);
    final kg = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final groupA = Group('g1', kg, [Member('A', idA.signPublicKey)]);
    final strangerGroup = Group('g1',
        Uint8List.fromList(List<int>.generate(32, (i) => 99)), const []);

    late LocationService a;
    late LocationService stranger;
    var strangerHandled = 0;
    a = LocationService(
      identity: idA, myId: aId, groups: [groupA],
      location: FakeLocation(const GeoPoint(0, 0)),
      random: Random(1), nowMs: () => 1000,
      broadcast: (f) => stranger.handleIncoming(f),
    );
    stranger = LocationService(
      identity: idStranger, myId: memberId(idStranger.signPublicKey),
      groups: [strangerGroup],
      location: FakeLocation(const GeoPoint(10, 10)),
      random: Random(2), nowMs: () => 1000,
      broadcast: (f) { strangerHandled++; },
    );

    await a.requestLocation(groupId: 'g1', targetId: 'whoever');
    await _settle();
    expect(strangerHandled, 0);
  });

  test('ne répond pas à sa propre demande « tous » (garde d\'écho)', () async {
    final idA = await Identity.generate();
    final aId = memberId(idA.signPublicKey);
    final kg = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final group = Group('g1', kg, [Member('A', idA.signPublicKey)]);

    final outgoing = <Uint8List>[];
    final a = LocationService(
      identity: idA, myId: aId, groups: [group],
      location: FakeLocation(const GeoPoint(0, 0)),
      random: Random(1), nowMs: () => 1000,
      broadcast: (f) => outgoing.add(f),
    );
    // A diffuse une demande "tous".
    await a.requestLocation(groupId: 'g1', targetId: kAllMembers);
    await _settle();
    expect(outgoing.length, 1); // la demande
    // On renvoie à A sa propre trame : il ne doit PAS répondre.
    await a.handleIncoming(outgoing.first);
    await _settle();
    expect(outgoing.length, 1); // toujours 1 : pas d'auto-réponse
  });

  test('une réponse dupliquée ne déclenche onLocated qu\'une fois', () async {
    final idA = await Identity.generate();
    final idB = await Identity.generate();
    final aId = memberId(idA.signPublicKey);
    final bId = memberId(idB.signPublicKey);
    final kg = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final group = Group('g1', kg,
        [Member('A', idA.signPublicKey), Member('B', idB.signPublicKey)]);

    final bOut = <Uint8List>[];
    late LocationService a;
    late LocationService b;
    a = LocationService(
      identity: idA, myId: aId, groups: [group],
      location: FakeLocation(const GeoPoint(0, 0)),
      random: Random(1), nowMs: () => 1000,
      broadcast: (f) => b.handleIncoming(f),
    );
    b = LocationService(
      identity: idB, myId: bId, groups: [group],
      location: FakeLocation(const GeoPoint(48.0, 2.0)),
      random: Random(2), nowMs: () => 1000,
      broadcast: (f) { bOut.add(f); a.handleIncoming(f); },
    );

    var count = 0;
    a.onLocated = (_) => count++;
    await a.requestLocation(groupId: 'g1', targetId: bId);
    await _settle();
    expect(count, 1);
    // Rejouer la réponse de B -> doit être dédupliquée.
    await a.handleIncoming(bOut.first);
    await _settle();
    expect(count, 1);
  });

  test('une demande hors fenêtre anti-rejeu n\'obtient pas de réponse', () async {
    final idA = await Identity.generate();
    final idB = await Identity.generate();
    final aId = memberId(idA.signPublicKey);
    final bId = memberId(idB.signPublicKey);
    final kg = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final group = Group('g1', kg,
        [Member('A', idA.signPublicKey), Member('B', idB.signPublicKey)]);

    late LocationService a;
    late LocationService b;
    a = LocationService(
      identity: idA, myId: aId, groups: [group],
      location: FakeLocation(const GeoPoint(0, 0)),
      random: Random(1), nowMs: () => 1000000,
      broadcast: (f) => b.handleIncoming(f),
      replayWindowMs: 30000,
    );
    b = LocationService(
      identity: idB, myId: bId, groups: [group],
      location: FakeLocation(const GeoPoint(48.0, 2.0)),
      random: Random(2), nowMs: () => 1000,
      broadcast: (f) => a.handleIncoming(f),
      replayWindowMs: 30000,
    );

    LocatedPosition? got;
    a.onLocated = (p) => got = p;
    await a.requestLocation(groupId: 'g1', targetId: bId);
    await _settle();
    expect(got, isNull);
  });
}

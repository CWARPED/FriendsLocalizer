import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:friends_localizer/crypto/identity.dart';
import 'package:friends_localizer/crypto/group.dart';
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/mesh/config.dart';
import 'package:friends_localizer/app/geo.dart';
import 'package:friends_localizer/app/member.dart';
import 'package:friends_localizer/app/fixed_location.dart';
import 'package:friends_localizer/server/server.dart';
import 'package:friends_localizer/server/relay_hub.dart';
import 'package:friends_localizer/server/key_directory.dart';
import 'package:friends_localizer/net/server_gateway_transport.dart';
import 'package:friends_localizer/net/mesh_session.dart';

void main() {
  late dynamic server;
  late int port;
  setUp(() async {
    server = await io.serve(
        buildServer(hub: RelayHub(scheduler: VirtualScheduler()), directory: KeyDirectory()),
        'localhost', 0);
    port = server.port as int;
  });
  tearDown(() async => server.close(force: true));

  test('A localise B de bout en bout via le relais (chiffré)', () async {
    final idA = await Identity.generate();
    final idB = await Identity.generate();
    final aId = memberId(idA.signPublicKey);
    final bId = memberId(idB.signPublicKey);
    final kg = Uint8List.fromList(List<int>.generate(32, (i) => i));
    Group group() => Group('g1', kg,
        [Member('A', idA.signPublicKey), Member('B', idB.signPublicKey)]);

    final sessionA = MeshSession(
      identity: idA, myId: aId, group: group(),
      transport: ServerGatewayTransport('ws://localhost:$port/relay'),
      location: FixedLocationProvider(const GeoPoint(0, 0)),
      random: Random(1), config: const MeshConfig(seenTtlMs: 60000, maxBackoffMs: 100),
    );
    final sessionB = MeshSession(
      identity: idB, myId: bId, group: group(),
      transport: ServerGatewayTransport('ws://localhost:$port/relay'),
      location: FixedLocationProvider(const GeoPoint(48.0, 2.0)),
      random: Random(2), config: const MeshConfig(seenTtlMs: 60000, maxBackoffMs: 100),
    );

    await sessionA.start();
    await sessionB.start();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    LocatedPosition? got;
    sessionA.onLocated = (p) => got = p;
    await sessionA.requestLocation(targetId: bId);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(got, isNotNull);
    expect(got!.responderId, bId);
    expect(got!.point.latitude, closeTo(48.0, 1e-9));
    expect(got!.point.longitude, closeTo(2.0, 1e-9));

    await sessionA.stop();
    await sessionB.stop();
  });

  test('syncRoster récupère les membres publiés et les ajoute au groupe', () async {
    final idA = await Identity.generate();
    final idB = await Identity.generate();
    final kg = Uint8List.fromList(List<int>.generate(32, (i) => i));

    final sessionA = MeshSession(
      identity: idA, myId: memberId(idA.signPublicKey),
      group: Group('g1', kg, [Member('A', idA.signPublicKey)]),
      transport: ServerGatewayTransport('ws://localhost:$port/relay'),
      location: FixedLocationProvider(const GeoPoint(0, 0)),
      random: Random(1),
      directoryBaseUrl: 'http://localhost:$port',
    );
    await sessionA.publishMe(name: 'Alice');

    final sessionB = MeshSession(
      identity: idB, myId: memberId(idB.signPublicKey),
      group: Group('g1', kg, [Member('B', idB.signPublicKey)]),
      transport: ServerGatewayTransport('ws://localhost:$port/relay'),
      location: FixedLocationProvider(const GeoPoint(1, 1)),
      random: Random(2),
      directoryBaseUrl: 'http://localhost:$port',
    );
    await sessionB.syncRoster();
    expect(sessionB.rosterMemberIds.contains(memberId(idA.signPublicKey)), isTrue);
  });
}

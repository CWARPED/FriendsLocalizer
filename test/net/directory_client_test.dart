import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/server/server.dart';
import 'package:friends_localizer/server/relay_hub.dart';
import 'package:friends_localizer/server/key_directory.dart';
import 'package:friends_localizer/net/directory_client.dart';

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

  test('publier puis récupérer le roster', () async {
    final client = DirectoryClient('http://localhost:$port');
    await client.publish(const DirectoryEntry(
        groupId: 'g1', memberId: 'a', name: 'Alice', signPublicKeyB64: 'AAAA'));
    await client.publish(const DirectoryEntry(
        groupId: 'g1', memberId: 'b', name: 'Bob', signPublicKeyB64: 'BBBB'));
    final roster = await client.roster('g1');
    expect(roster.length, 2);
    expect(roster.map((e) => e.memberId).toSet(), {'a', 'b'});
  });

  test('roster d\'un groupe inconnu est vide', () async {
    final client = DirectoryClient('http://localhost:$port');
    expect(await client.roster('zzz'), isEmpty);
  });
}

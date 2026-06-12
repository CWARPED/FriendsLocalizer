import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/server/server.dart';
import 'package:friends_localizer/server/relay_hub.dart';
import 'package:friends_localizer/server/key_directory.dart';
import 'package:friends_localizer/ui/store.dart';
import 'package:friends_localizer/ui/real_repository.dart';
import 'package:friends_localizer/ui/models.dart';

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

  test('deux dépôts réels se localisent via le relais local', () async {
    // URL serveur SANS /relay : l'appli doit l'ajouter elle-même (relayWsUrl).
    final ws = 'ws://localhost:$port';

    final alice = await RealRepository.load(MemoryStore());
    await alice.createIdentity('Alice');
    alice.updateSettings(AppSettings(serverUrl: ws, myLat: 48.0, myLon: 2.0));
    final g = await alice.createGroup('Festival');
    final invite = alice.inviteFor(g.id);

    final bob = await RealRepository.load(MemoryStore());
    await bob.createIdentity('Bob');
    bob.updateSettings(AppSettings(serverUrl: ws, myLat: 10.0, myLon: 20.0));
    await bob.joinFromInvite(invite);

    await alice.ensureConnected();
    await bob.ensureConnected();
    await alice.ensureConnected(); // resync: Alice apprend la clé de Bob
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Point 1 : après resync via l'annuaire, Alice (créatrice) voit Bob dans
    // sa liste de membres affichée.
    expect(alice.members(g.id).map((m) => m.name), contains('Bob'));

    final bobId = bob.identity!.memberId;
    await alice.requestLocation(groupId: g.id, targetId: bobId);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final pos = alice.located(bobId);
    expect(pos, isNotNull);
    expect(pos!.point.latitude, closeTo(10.0, 1e-9));
    expect(pos.point.longitude, closeTo(20.0, 1e-9));

    await alice.dispose();
    await bob.dispose();
  });

  test('refreshGroups synchronise le roster sans passer par Localiser', () async {
    final ws = 'ws://localhost:$port';

    final alice = await RealRepository.load(MemoryStore());
    await alice.createIdentity('Alice');
    alice.updateSettings(AppSettings(serverUrl: ws));
    final g = await alice.createGroup('Festival');
    final invite = alice.inviteFor(g.id);

    final bob = await RealRepository.load(MemoryStore());
    await bob.createIdentity('Bob');
    bob.updateSettings(AppSettings(serverUrl: ws));
    await bob.joinFromInvite(invite);

    // Avant toute synchro, chacun ne voit que lui-même.
    expect(alice.groups.first.memberCount, 1);

    // Bob se publie, puis Alice rafraîchit : elle doit voir Bob — sans jamais
    // ouvrir l'écran Localiser (aucun appel à ensureConnected).
    await bob.refreshGroups();
    await alice.refreshGroups();

    expect(alice.members(g.id).map((m) => m.name), contains('Bob'));
    expect(alice.groups.first.memberCount, 2);

    await alice.dispose();
    await bob.dispose();
  });

  test('rejoindre publie tout de suite : Alice voit Bob sans que Bob ne fasse rien',
      () async {
    final ws = 'ws://localhost:$port';

    final alice = await RealRepository.load(MemoryStore());
    await alice.createIdentity('Alice');
    alice.updateSettings(AppSettings(serverUrl: ws));
    final g = await alice.createGroup('Festival');
    final invite = alice.inviteFor(g.id);

    final bob = await RealRepository.load(MemoryStore());
    await bob.createIdentity('Bob');
    bob.updateSettings(AppSettings(serverUrl: ws));
    await bob.joinFromInvite(invite); // publie Bob automatiquement

    // Laisse la publication automatique (non bloquante) se terminer.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Alice rafraîchit (comme en ouvrant le groupe) : elle voit Bob, alors que
    // Bob n'a appelé NI refreshGroups NI ensureConnected.
    await alice.refreshGroups();
    expect(alice.members(g.id).map((m) => m.name), contains('Bob'));

    await alice.dispose();
    await bob.dispose();
  });
}

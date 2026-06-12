import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/store.dart';
import 'package:friends_localizer/ui/real_repository.dart';
import 'package:friends_localizer/ui/models.dart';
import 'package:friends_localizer/app/onboarding.dart';

void main() {
  test('pas d\'identité au départ, puis créée et persistée', () async {
    final store = MemoryStore();
    final repo = await RealRepository.load(store);
    expect(repo.identity, isNull);
    await repo.createIdentity('Marie');
    expect(repo.identity!.name, 'Marie');
    expect(repo.identity!.memberId.length, 64);

    final repo2 = await RealRepository.load(store);
    expect(repo2.identity!.name, 'Marie');
    expect(repo2.identity!.memberId, repo.identity!.memberId);
  });

  test('créer un groupe : roster contient moi, invitation décodable', () async {
    final store = MemoryStore();
    final repo = await RealRepository.load(store);
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    expect(g.name, 'Festival');
    expect(repo.members(g.id).any((m) => m.name == 'Marie'), isTrue);

    final invite = GroupInvite.decode(repo.inviteFor(g.id));
    expect(invite.groupName, 'Festival');
    expect(invite.groupSecret.length, 32);

    final repo2 = await RealRepository.load(store);
    expect(repo2.groups.any((x) => x.id == g.id && x.name == 'Festival'), isTrue);
  });

  test('rejoindre via invitation ajoute le groupe avec son nom', () async {
    final creator = await RealRepository.load(MemoryStore());
    await creator.createIdentity('Alice');
    final g = await creator.createGroup('Coloc');
    final payload = creator.inviteFor(g.id);

    final repo = await RealRepository.load(MemoryStore());
    await repo.createIdentity('Marie');
    await repo.joinFromInvite(payload);
    expect(repo.groups.any((x) => x.name == 'Coloc'), isTrue);
    final gid = repo.groups.firstWhere((x) => x.name == 'Coloc').id;
    expect(repo.members(gid).any((m) => m.name == 'Alice'), isTrue);
  });

  test('joinFromInvite est idempotent', () async {
    final creator = await RealRepository.load(MemoryStore());
    await creator.createIdentity('Alice');
    final g = await creator.createGroup('Coloc');
    final payload = creator.inviteFor(g.id);
    final repo = await RealRepository.load(MemoryStore());
    await repo.createIdentity('Marie');
    await repo.joinFromInvite(payload);
    await repo.joinFromInvite(payload);
    expect(repo.groups.where((x) => x.id == g.id).length, 1);
  });

  test('un store corrompu ne fait pas planter le chargement (repli sur vide)', () async {
    final store = MemoryStore({
      'identity.bytes': 'pas-du-base64-!!!',
      'groups.json': 'pas du json {{{',
      'settings.json': '<<<corrompu>>>',
    });
    final repo = await RealRepository.load(store); // ne doit PAS lever
    expect(repo.identity, isNull);
    expect(repo.groups, isEmpty);
    expect(repo.settings.serverUrl, 'ws://127.0.0.1:8080'); // défaut conservé
  });

  test('les réglages (adresse serveur) sont persistés', () async {
    final store = MemoryStore();
    final repo = await RealRepository.load(store);
    repo.updateSettings(const AppSettings(
        serverUrl: 'ws://relay:9000', internetEnabled: false));
    final repo2 = await RealRepository.load(store);
    expect(repo2.settings.serverUrl, 'ws://relay:9000');
    expect(repo2.settings.internetEnabled, isFalse);
  });

  test('la position desktop (lat/lon) est persistée', () async {
    final store = MemoryStore();
    final repo = await RealRepository.load(store);
    repo.updateSettings(const AppSettings(myLat: 48.85, myLon: 2.35));
    final repo2 = await RealRepository.load(store);
    expect(repo2.settings.myLat, closeTo(48.85, 1e-9));
    expect(repo2.settings.myLon, closeTo(2.35, 1e-9));
  });

  test('leaveGroup retire le groupe et persiste', () async {
    final store = MemoryStore();
    final repo = await RealRepository.load(store);
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    await repo.leaveGroup(g.id);
    expect(repo.groups.any((x) => x.id == g.id), isFalse);
    final repo2 = await RealRepository.load(store);
    expect(repo2.groups.any((x) => x.id == g.id), isFalse);
  });
}

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/app_repository.dart';
import 'package:friends_localizer/ui/fake_repository.dart';
import 'package:friends_localizer/app/onboarding.dart';

void main() {
  test('pas d\'identité au départ, puis créée', () async {
    final repo = FakeRepository();
    expect(repo.identity, isNull);
    await repo.createIdentity('Marie');
    expect(repo.identity!.name, 'Marie');
    expect(repo.identity!.memberId.length, 64);
  });

  test('créer un groupe l\'ajoute à la liste avec moi comme membre', () async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    expect(repo.groups.any((x) => x.id == g.id), isTrue);
    expect(g.name, 'Festival');
    final members = repo.members(g.id);
    expect(members.any((m) => m.name == 'Marie'), isTrue);
  });

  test('inviteFor produit un GroupInvite décodable', () async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    final payload = repo.inviteFor(g.id);
    final invite = GroupInvite.decode(payload);
    expect(invite.groupId, g.id);
    expect(invite.groupSecret.length, 32);
  });

  test('joinFromInvite ajoute un groupe', () async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final creator = FakeRepository();
    await creator.createIdentity('Alice');
    final g = await creator.createGroup('Coloc');
    final payload = creator.inviteFor(g.id);

    await repo.joinFromInvite(payload);
    expect(repo.groups.any((x) => x.name == 'Coloc'), isTrue);
  });

  test('updateSettings notifie et persiste en mémoire', () async {
    final repo = FakeRepository();
    var notified = 0;
    repo.addListener(() => notified++);
    repo.updateSettings(const AppSettings(serverUrl: 'ws://x:8080'));
    expect(repo.settings.serverUrl, 'ws://x:8080');
    expect(notified, greaterThan(0));
  });

  test('AppSettings copyWith préserve la position', () {
    const s = AppSettings(myLat: 48.85, myLon: 2.35);
    final s2 = s.copyWith(serverUrl: 'ws://x');
    expect(s2.myLat, 48.85);
    expect(s2.myLon, 2.35);
    expect(s2.serverUrl, 'ws://x');
  });

  test('requestLocation (fake) fournit une position pour la cible', () async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    await repo.ensureConnected();
    expect(repo.located('tom00'), isNull);
    await repo.requestLocation(groupId: g.id, targetId: 'tom00');
    final pos = repo.located('tom00');
    expect(pos, isNotNull);
    expect(pos!.responderId, 'tom00');
  });

  test('leaveGroup retire le groupe de la liste', () async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival');
    expect(repo.groups.any((x) => x.id == g.id), isTrue);
    await repo.leaveGroup(g.id);
    expect(repo.groups.any((x) => x.id == g.id), isFalse);
    // Le secret du groupe est effacé : une invitation après départ est inerte.
    final invite = GroupInvite.decode(repo.inviteFor(g.id));
    expect(invite.groupSecret, equals(Uint8List(32)));
  });
}

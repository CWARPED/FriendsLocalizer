import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/server/key_directory.dart';

MemberEntry entry(String group, String id, String name) => MemberEntry(
      groupId: group, memberId: id, name: name, signPublicKeyB64: 'AAAA');

void main() {
  test('publish + roster liste les membres d\'un groupe', () {
    final dir = KeyDirectory();
    dir.publish(entry('g1', 'a', 'Alice'));
    dir.publish(entry('g1', 'b', 'Bob'));
    final r = dir.roster('g1');
    expect(r.length, 2);
    expect(r.map((e) => e.memberId).toSet(), {'a', 'b'});
  });

  test('republier le même memberId met à jour (pas de doublon)', () {
    final dir = KeyDirectory();
    dir.publish(entry('g1', 'a', 'Alice'));
    dir.publish(entry('g1', 'a', 'Alice2'));
    final r = dir.roster('g1');
    expect(r.length, 1);
    expect(r.first.name, 'Alice2');
  });

  test('roster d\'un groupe inconnu est vide', () {
    expect(KeyDirectory().roster('zzz'), isEmpty);
  });

  test('MemberEntry round-trip JSON', () {
    final e = entry('g1', 'a', 'Alice');
    final back = MemberEntry.fromJson(e.toJson());
    expect(back.groupId, 'g1');
    expect(back.memberId, 'a');
    expect(back.name, 'Alice');
    expect(back.signPublicKeyB64, 'AAAA');
  });
}

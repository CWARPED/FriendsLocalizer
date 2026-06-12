import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/member.dart';
import 'package:friends_localizer/ui/fake_repository.dart';

void main() {
  test('requestLocation("*") fabrique une position pour chaque autre membre',
      () async {
    final repo = FakeRepository();
    await repo.createIdentity('Marie');
    final g = await repo.createGroup('Festival'); // ajoute tom00 + ana00
    await repo.ensureConnected();
    await repo.requestLocation(groupId: g.id, targetId: kAllMembers);
    expect(repo.located('tom00'), isNotNull);
    expect(repo.located('ana00'), isNotNull);
    // positions distinctes (directions/distances différentes)
    expect(repo.located('tom00')!.point.latitude,
        isNot(repo.located('ana00')!.point.latitude));
  });
}

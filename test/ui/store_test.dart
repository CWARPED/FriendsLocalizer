import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/store.dart';

void main() {
  test('MemoryStore lit ce qu\'il a écrit', () async {
    final s = MemoryStore();
    expect(s.getString('k'), isNull);
    await s.setString('k', 'v');
    expect(s.getString('k'), 'v');
  });

  test('MemoryStore peut être pré-rempli', () {
    final s = MemoryStore({'a': '1'});
    expect(s.getString('a'), '1');
  });
}

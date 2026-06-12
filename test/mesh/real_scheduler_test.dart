import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/mesh/real_scheduler.dart';

void main() {
  test('exécute une tâche après le délai', () {
    fakeAsync((async) {
      final s = RealScheduler();
      var ran = false;
      s.schedule(100, () => ran = true);
      expect(ran, isFalse);
      async.elapse(const Duration(milliseconds: 99));
      expect(ran, isFalse);
      async.elapse(const Duration(milliseconds: 1));
      expect(ran, isTrue);
    });
  });

  test('nowMs progresse avec le temps simulé', () {
    fakeAsync((async) {
      final s = RealScheduler();
      final t0 = s.nowMs();
      async.elapse(const Duration(milliseconds: 500));
      expect(s.nowMs() - t0, 500);
    });
  });

  test('un délai négatif s\'exécute au prochain tick (>= maintenant)', () {
    fakeAsync((async) {
      final s = RealScheduler();
      var ran = false;
      s.schedule(-10, () => ran = true);
      async.elapse(Duration.zero);
      expect(ran, isTrue);
    });
  });
}

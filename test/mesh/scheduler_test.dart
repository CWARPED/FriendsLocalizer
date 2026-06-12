import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/mesh/scheduler.dart';

void main() {
  test('exécute les tâches dans l\'ordre temporel', () {
    final s = VirtualScheduler();
    final order = <String>[];
    s.schedule(30, () => order.add('c'));
    s.schedule(10, () => order.add('a'));
    s.schedule(20, () => order.add('b'));
    s.runUntilIdle();
    expect(order, ['a', 'b', 'c']);
    expect(s.nowMs(), 30);
  });

  test('départage les égalités en FIFO (ordre de planification)', () {
    final s = VirtualScheduler();
    final order = <String>[];
    s.schedule(10, () => order.add('first'));
    s.schedule(10, () => order.add('second'));
    s.runUntilIdle();
    expect(order, ['first', 'second']);
  });

  test('une tâche peut en planifier une autre', () {
    final s = VirtualScheduler();
    final order = <String>[];
    s.schedule(10, () {
      order.add('a');
      s.schedule(5, () => order.add('b'));
    });
    s.runUntilIdle();
    expect(order, ['a', 'b']);
    expect(s.nowMs(), 15);
  });

  test('advance avance l\'horloge sans exécuter les tâches', () {
    final s = VirtualScheduler();
    var ran = false;
    s.schedule(100, () => ran = true);
    s.advance(50);
    expect(s.nowMs(), 50);
    expect(ran, isFalse);
  });

  test('runNext retourne false quand la file est vide', () {
    final s = VirtualScheduler();
    expect(s.runNext(), isFalse);
  });
}

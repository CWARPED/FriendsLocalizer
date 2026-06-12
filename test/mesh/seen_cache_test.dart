import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/mesh/seen_cache.dart';

void main() {
  Uint8List id(int seed) =>
      Uint8List.fromList(List<int>.generate(16, (i) => (i + seed) & 0xFF));

  test('un msgId inconnu n\'est pas vu, puis vu après mark', () {
    final s = VirtualScheduler();
    final c = SeenCache(scheduler: s, ttlMs: 1000);
    final m = id(1);
    expect(c.seen(m), isFalse);
    c.mark(m);
    expect(c.seen(m), isTrue);
  });

  test('distingue deux msgId différents', () {
    final s = VirtualScheduler();
    final c = SeenCache(scheduler: s, ttlMs: 1000);
    c.mark(id(1));
    expect(c.seen(id(1)), isTrue);
    expect(c.seen(id(2)), isFalse);
  });

  test('un msgId expire après le TTL', () {
    final s = VirtualScheduler();
    final c = SeenCache(scheduler: s, ttlMs: 1000);
    final m = id(1);
    c.mark(m);
    s.advance(1001);
    expect(c.seen(m), isFalse);
  });

  test('purgeExpired retire les entrées expirées et garde les valides', () {
    final s = VirtualScheduler();
    final c = SeenCache(scheduler: s, ttlMs: 1000);
    c.mark(id(1));
    s.advance(500);
    c.mark(id(2)); // expire à t=1500
    s.advance(600); // t=1100 : id(1) expiré, id(2) encore valide
    c.purgeExpired();
    expect(c.length, 1);
    expect(c.seen(id(2)), isTrue);
    expect(c.seen(id(1)), isFalse);
  });
}

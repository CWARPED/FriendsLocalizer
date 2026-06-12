import 'dart:async';
import 'package:clock/clock.dart';
import 'scheduler.dart';

/// MeshScheduler de production : horloge murale + Timer. Pour les tests
/// déterministes, l'envelopper dans `fakeAsync(...)`.
class RealScheduler implements MeshScheduler {
  @override
  int nowMs() => clock.now().millisecondsSinceEpoch;

  @override
  void schedule(int delayMs, void Function() callback) {
    final ms = delayMs < 0 ? 0 : delayMs;
    Timer(Duration(milliseconds: ms), callback);
  }
}

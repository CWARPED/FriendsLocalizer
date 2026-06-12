/// Abstraction d'horloge + planification. Le moteur de mesh n'utilise jamais
/// l'horloge murale directement, pour rester déterministe et testable.
abstract class MeshScheduler {
  int nowMs();
  void schedule(int delayMs, void Function() callback);
}

/// Implémentation à temps virtuel : aucune attente réelle. Le temps n'avance
/// que lorsqu'une tâche planifiée est exécutée (ou via [advance]).
class VirtualScheduler implements MeshScheduler {
  int _now = 0;
  int _seq = 0;
  final List<_ScheduledTask> _queue = [];

  @override
  int nowMs() => _now;

  @override
  void schedule(int delayMs, void Function() callback) {
    final at = _now + (delayMs < 0 ? 0 : delayMs);
    _queue.add(_ScheduledTask(at, _seq++, callback));
  }

  /// Exécute la prochaine tâche due (par temps croissant, puis FIFO).
  /// Retourne false si la file est vide.
  bool runNext() {
    if (_queue.isEmpty) return false;
    var idx = 0;
    for (var i = 1; i < _queue.length; i++) {
      final a = _queue[i];
      final b = _queue[idx];
      if (a.time < b.time || (a.time == b.time && a.seq < b.seq)) idx = i;
    }
    final task = _queue.removeAt(idx);
    if (task.time > _now) _now = task.time;
    task.callback();
    return true;
  }

  /// Exécute toutes les tâches jusqu'à épuisement de la file.
  void runUntilIdle() {
    while (runNext()) {}
  }

  /// Avance l'horloge de [deltaMs] SANS exécuter les tâches (utile pour tester
  /// l'expiration des caches). Utiliser [runUntilIdle] pour exécuter les tâches.
  void advance(int deltaMs) {
    _now += deltaMs < 0 ? 0 : deltaMs;
  }
}

class _ScheduledTask {
  final int time;
  final int seq;
  final void Function() callback;
  _ScheduledTask(this.time, this.seq, this.callback);
}

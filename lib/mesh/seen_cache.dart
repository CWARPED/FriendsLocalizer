import 'dart:typed_data';
import 'scheduler.dart';

/// Cache des msgId récemment vus, borné dans le temps. Sert à la déduplication
/// (un message déjà vu n'est ni re-livré ni re-diffusé).
class SeenCache {
  final MeshScheduler scheduler;
  final int ttlMs;
  final Map<String, int> _expiry = {}; // clé msgId -> instant d'expiration (ms)

  SeenCache({required this.scheduler, required this.ttlMs});

  static String _key(Uint8List msgId) => String.fromCharCodes(msgId);

  bool seen(Uint8List msgId) {
    final k = _key(msgId);
    final exp = _expiry[k];
    if (exp == null) return false;
    if (exp <= scheduler.nowMs()) {
      _expiry.remove(k);
      return false;
    }
    return true;
  }

  void mark(Uint8List msgId) {
    _expiry[_key(msgId)] = scheduler.nowMs() + ttlMs;
  }

  /// Nombre d'entrées actuellement mémorisées (expirées comprises tant qu'elles
  /// n'ont pas été purgées). Utile aux tests et au monitoring.
  int get length => _expiry.length;

  /// Retire toutes les entrées expirées. À appeler périodiquement sur un nœud
  /// longue durée (l'éviction sur `seen()` est sinon paresseuse).
  void purgeExpired() {
    final now = scheduler.nowMs();
    _expiry.removeWhere((_, exp) => exp <= now);
  }
}

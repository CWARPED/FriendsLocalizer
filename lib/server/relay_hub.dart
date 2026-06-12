import 'dart:typed_data';
import '../crypto/envelope.dart';
import '../mesh/scheduler.dart';
import '../mesh/seen_cache.dart';

/// Relais internet de trames chiffrées opaques entre clients connectés.
/// Dédup par msgId + décrément de TTL + fan-out. Ne déchiffre JAMAIS.
class RelayHub {
  final SeenCache _seen;
  int _nextId = 0;
  final Map<int, void Function(Uint8List frame)> _conns = {};

  RelayHub({required MeshScheduler scheduler, int seenTtlMs = 60000})
      : _seen = SeenCache(scheduler: scheduler, ttlMs: seenTtlMs);

  int connect(void Function(Uint8List frame) send) {
    final id = _nextId++;
    _conns[id] = send;
    return id;
  }

  void disconnect(int connId) => _conns.remove(connId);

  int get connectionCount => _conns.length;

  void ingest(int fromConnId, Uint8List frame) {
    final Envelope env;
    try {
      env = Envelope.fromBytes(frame);
    } catch (_) {
      return;
    }
    if (_seen.seen(env.msgId)) return;
    _seen.mark(env.msgId);
    if (env.ttl <= 1) return;
    final relayed = env.withDecrementedTtl().toBytes();
    for (final entry in _conns.entries) {
      if (entry.key == fromConnId) continue;
      entry.value(relayed);
    }
  }
}

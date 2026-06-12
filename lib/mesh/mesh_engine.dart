// lib/mesh/mesh_engine.dart
import 'dart:math';
import 'dart:typed_data';
import '../crypto/envelope.dart';
import 'config.dart';
import 'scheduler.dart';
import 'seen_cache.dart';
import 'transport.dart';

/// Moteur de mesh épidémique discipliné. Opère sur des trames (Envelope
/// sérialisées) ; il lit msgId + ttl SANS déchiffrer. La livraison locale
/// ([onDeliver]) laisse la couche applicative tenter d'ouvrir l'enveloppe.
class MeshEngine {
  final MeshScheduler scheduler;
  final MeshTransport transport;
  final MeshConfig config;
  final Random random;
  final void Function(Uint8List frame) onDeliver;
  final SeenCache _seen;

  /// msgId (clé) -> nombre de fois que le message a été entendu, tant qu'un
  /// relais est en attente pour lui.
  final Map<String, int> _pendingHeard = {};

  /// Trames retenues pour le store-and-forward.
  final List<_Buffered> _store = [];

  MeshEngine({
    required this.scheduler,
    required this.transport,
    required this.config,
    required this.random,
    required this.onDeliver,
    SeenCache? seenCache,
  }) : _seen = seenCache ?? SeenCache(scheduler: scheduler, ttlMs: config.seenTtlMs);

  static String _key(Uint8List msgId) => String.fromCharCodes(msgId);

  /// Origine un nouveau message : marque vu, bufferise, diffuse à pleine TTL.
  /// Idempotent : ré-originer un msgId déjà vu est ignoré (utiliser un nouveau
  /// msgId pour un nouveau message).
  void originate(Uint8List frame) {
    final Envelope env;
    try {
      env = Envelope.fromBytes(frame);
    } catch (_) {
      return;
    }
    if (_seen.seen(env.msgId)) return; // déjà originé/vu : idempotent
    // Message originé : marqué vu pour que notre propre écho soit dédupliqué ;
    // il ne passe pas par la planification de relais.
    _seen.mark(env.msgId);
    _buffer(frame);
    transport.send(frame);
  }

  /// Reçoit une trame d'un voisin.
  void handleInbound(Uint8List frame) {
    final Envelope env;
    try {
      env = Envelope.fromBytes(frame);
    } catch (_) {
      return; // trame malformée : ignorée
    }
    final key = _key(env.msgId);
    if (_seen.seen(env.msgId)) {
      // Doublon : alimente le compteur de suppression d'un relais en attente.
      final c = _pendingHeard[key];
      if (c != null) _pendingHeard[key] = c + 1;
      return;
    }
    _seen.mark(env.msgId);
    onDeliver(frame);
    _buffer(frame);
    if (env.ttl > 1) {
      _pendingHeard[key] = 1;
      final span = config.maxBackoffMs - config.minBackoffMs;
      final backoff =
          config.minBackoffMs + (span <= 0 ? 0 : random.nextInt(span + 1));
      scheduler.schedule(backoff, () => _fireRelay(key, env));
    }
  }

  void _fireRelay(String key, Envelope env) {
    final heard = _pendingHeard.remove(key) ?? 0;
    if (heard >= config.suppressionThreshold) {
      return; // assez de relais entendus : on supprime le nôtre
    }
    transport.send(env.withDecrementedTtl().toBytes());
  }

  void _buffer(Uint8List frame) {
    if (_store.length >= config.maxStoreFrames) {
      _store.removeAt(0); // éviction FIFO de la plus ancienne
    }
    _store.add(_Buffered(frame, scheduler.nowMs() + config.storeForwardMs));
  }

  /// Appelé quand un nouveau voisin apparaît : re-diffuse les trames encore
  /// valides (store-and-forward), pour franchir les trous du réseau.
  ///
  /// Note : les trames sont ré-émises à leur TTL d'ORIGINE (le store-and-forward
  /// ne consomme pas de saut). Le TTL n'est donc pas une garantie stricte de
  /// rayon en nombre de sauts lorsque le S&F est actif.
  void onNeighborAppeared() {
    final now = scheduler.nowMs();
    _store.removeWhere((b) => b.expiry <= now);
    for (final b in _store) {
      transport.send(b.frame);
    }
  }
}

class _Buffered {
  final Uint8List frame;
  final int expiry;
  _Buffered(this.frame, this.expiry);
}

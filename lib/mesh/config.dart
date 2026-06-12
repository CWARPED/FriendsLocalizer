// lib/mesh/config.dart

/// Paramètres de contrôle de flood du moteur de mesh.
class MeshConfig {
  /// Seuil de suppression : nombre total de réceptions du même message
  /// (première réception comprise) à partir duquel on annule notre propre
  /// relais. Exemple : 3 → on supprime dès qu'on a reçu le message 3 fois.
  final int suppressionThreshold;

  /// Bornes du backoff aléatoire (ms) avant de relayer.
  final int minBackoffMs;
  final int maxBackoffMs;

  /// Durée de rétention d'un msgId dans le cache de déduplication (ms).
  final int seenTtlMs;

  /// Durée de rétention d'une trame pour le store-and-forward (ms).
  final int storeForwardMs;

  /// Nombre maximum de trames retenues pour le store-and-forward. Au-delà, la
  /// plus ancienne est évincée (FIFO).
  final int maxStoreFrames;

  const MeshConfig({
    this.suppressionThreshold = 3,
    this.minBackoffMs = 20,
    this.maxBackoffMs = 100,
    this.seenTtlMs = 60000,
    this.storeForwardMs = 30000,
    this.maxStoreFrames = 256,
  })  : assert(suppressionThreshold >= 1),
        assert(minBackoffMs >= 0 && maxBackoffMs >= minBackoffMs),
        assert(storeForwardMs > 0),
        assert(maxStoreFrames > 0),
        // Invariant : le TTL de dédup doit dépasser le backoff max, sinon un
        // msgId peut expirer pendant qu'un relais est en attente (fuite/relais
        // en double). Vrai pour toute config saine.
        assert(seenTtlMs > maxBackoffMs);

  /// Fabrique validante : applique les invariants en TOUT mode (les `assert`
  /// du constructeur const sont effacés en release). À utiliser en production.
  factory MeshConfig.validated({
    required int suppressionThreshold,
    required int minBackoffMs,
    required int maxBackoffMs,
    required int seenTtlMs,
    required int storeForwardMs,
    required int maxStoreFrames,
  }) {
    if (suppressionThreshold < 1) {
      throw ArgumentError.value(suppressionThreshold, 'suppressionThreshold', '>= 1 requis');
    }
    if (minBackoffMs < 0 || maxBackoffMs < minBackoffMs) {
      throw ArgumentError('backoff invalide : 0 <= min <= max requis');
    }
    if (storeForwardMs <= 0) {
      throw ArgumentError.value(storeForwardMs, 'storeForwardMs', '> 0 requis');
    }
    if (maxStoreFrames <= 0) {
      throw ArgumentError.value(maxStoreFrames, 'maxStoreFrames', '> 0 requis');
    }
    // Invariant de correction : un msgId ne doit pas expirer pendant qu'un
    // relais est en attente (sinon double livraison/relais).
    if (seenTtlMs <= maxBackoffMs) {
      throw ArgumentError('seenTtlMs ($seenTtlMs) doit dépasser maxBackoffMs ($maxBackoffMs)');
    }
    return MeshConfig(
      suppressionThreshold: suppressionThreshold,
      minBackoffMs: minBackoffMs,
      maxBackoffMs: maxBackoffMs,
      seenTtlMs: seenTtlMs,
      storeForwardMs: storeForwardMs,
      maxStoreFrames: maxStoreFrames,
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/mesh/config.dart';

void main() {
  test('validated accepte une config saine', () {
    final c = MeshConfig.validated(
      suppressionThreshold: 3, minBackoffMs: 20, maxBackoffMs: 100,
      seenTtlMs: 60000, storeForwardMs: 30000, maxStoreFrames: 256);
    expect(c.suppressionThreshold, 3);
  });

  test('validated rejette seenTtlMs <= maxBackoffMs', () {
    expect(
      () => MeshConfig.validated(
        suppressionThreshold: 3, minBackoffMs: 20, maxBackoffMs: 100,
        seenTtlMs: 50, storeForwardMs: 30000, maxStoreFrames: 256),
      throwsArgumentError,
    );
  });

  test('validated rejette un seuil de suppression < 1', () {
    expect(
      () => MeshConfig.validated(
        suppressionThreshold: 0, minBackoffMs: 20, maxBackoffMs: 100,
        seenTtlMs: 60000, storeForwardMs: 30000, maxStoreFrames: 256),
      throwsArgumentError,
    );
  });

  test('validated rejette maxBackoffMs < minBackoffMs', () {
    expect(
      () => MeshConfig.validated(
        suppressionThreshold: 3, minBackoffMs: 100, maxBackoffMs: 20,
        seenTtlMs: 60000, storeForwardMs: 30000, maxStoreFrames: 256),
      throwsArgumentError,
    );
  });
}

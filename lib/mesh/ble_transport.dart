import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'transport.dart';

/// Côté Dart du transport BLE. `send` pousse la trame au natif via MethodChannel ;
/// les trames et événements de voisinage entrants arrivent par l'EventChannel et
/// sont routés vers [onFrame] / [onNeighbor] (branchés sur le moteur par la façade).
class BleMeshTransport implements MeshTransport {
  static const MethodChannel _method = MethodChannel('fl/ble');
  static const EventChannel _events = EventChannel('fl/ble/events');

  void Function(Uint8List frame)? onFrame;
  void Function()? onNeighbor;

  late final StreamSubscription _sub;

  BleMeshTransport() {
    _sub = _events.receiveBroadcastStream().listen(
      _onEvent,
      onError: (Object e) => debugPrint('BleMeshTransport event error: $e'),
    );
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    switch (event['type']) {
      case 'frame':
        final data = event['data'];
        if (data is Uint8List) onFrame?.call(data);
        break;
      case 'neighbor':
        onNeighbor?.call();
        break;
    }
  }

  /// Démarre l'advertising + scan natifs (et le ForegroundService Android).
  Future<void> start() => _method.invokeMethod('start');

  /// Arrête le natif.
  Future<void> stop() => _method.invokeMethod('stop');

  @override
  void send(Uint8List frame) {
    // Fire-and-forget : le moteur n'attend pas l'ACK natif. On absorbe les
    // échecs (BLE indisponible, permission refusée) — le mesh tolère la perte.
    _method.invokeMethod<void>('broadcast', frame).catchError((Object e) {
      debugPrint('BleMeshTransport.send error: $e');
    });
  }

  Future<void> dispose() async {
    await _sub.cancel();
  }
}

import 'dart:math';
import 'dart:typed_data';
import '../crypto/envelope.dart';
import 'config.dart';
import 'mesh_engine.dart';
import 'msg_id.dart';
import 'scheduler.dart';
import 'transport.dart';

/// Façade de production : assemble le moteur, le transport et le scheduler,
/// route les entrées du transport vers le moteur, et expose l'émission.
class MeshNode {
  final MeshEngine engine;
  final Random _random;

  MeshNode({
    required MeshScheduler scheduler,
    required MeshTransport transport,
    required MeshConfig config,
    required Random random,
    required void Function(Uint8List frame) onDeliver,
    required void Function(
      void Function(Uint8List frame) handleFrame,
      void Function() handleNeighbor,
    ) bindInbound,
  })  : _random = random,
        engine = MeshEngine(
          scheduler: scheduler,
          transport: transport,
          config: config,
          random: random,
          onDeliver: onDeliver,
        ) {
    bindInbound(engine.handleInbound, engine.onNeighborAppeared);
  }

  /// Émet une enveloppe DÉJÀ scellée (Plan 4) telle quelle.
  void broadcastSealed(Uint8List sealedFrame) => engine.originate(sealedFrame);

  /// Fabrique une enveloppe de transport non chiffrée autour de [payload]
  /// (utilisée pour les tests / messages de contrôle) avec un msgId généré.
  void broadcastNew(Uint8List payload, {required int ttl, required int type}) {
    final frame = Envelope(
      msgId: generateMsgId(_random),
      type: type,
      ttl: ttl,
      timestampMs: 0,
      senderPub: Uint8List(32),
      ciphertext: payload,
      signature: Uint8List(64),
    ).toBytes();
    engine.originate(frame);
  }
}

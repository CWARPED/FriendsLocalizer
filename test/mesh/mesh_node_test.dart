import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/envelope.dart';
import 'package:friends_localizer/mesh/config.dart';
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/mesh/transport.dart';
import 'package:friends_localizer/mesh/mesh_node.dart';

Uint8List buildFrame(Uint8List msgId, int ttl) => Envelope(
      msgId: msgId, type: 1, ttl: ttl, timestampMs: 0,
      senderPub: Uint8List(32), ciphertext: Uint8List.fromList([1, 2, 3]),
      signature: Uint8List(64)).toBytes();

class FakeTransport implements MeshTransport {
  final List<Uint8List> sent = [];
  void Function(Uint8List)? onFrame;
  void Function()? onNeighbor;
  @override
  void send(Uint8List frame) => sent.add(frame);
}

void main() {
  test('une trame entrante du transport est livrée via le moteur', () {
    final s = VirtualScheduler();
    final tx = FakeTransport();
    final delivered = <Uint8List>[];
    MeshNode(
      scheduler: s,
      transport: tx,
      config: const MeshConfig(seenTtlMs: 60000, maxBackoffMs: 100),
      random: Random(1),
      bindInbound: (handleFrame, handleNeighbor) {
        tx.onFrame = handleFrame;
        tx.onNeighbor = handleNeighbor;
      },
      onDeliver: (f) => delivered.add(f),
    );
    tx.onFrame!(buildFrame(Uint8List(16), 1));
    expect(delivered.length, 1);
  });

  test('broadcastNew d\'un nouveau message passe par le transport', () {
    final s = VirtualScheduler();
    final tx = FakeTransport();
    final node = MeshNode(
      scheduler: s,
      transport: tx,
      config: const MeshConfig(seenTtlMs: 60000, maxBackoffMs: 100),
      random: Random(1),
      bindInbound: (f, n) {},
      onDeliver: (_) {},
    );
    node.broadcastNew(Uint8List.fromList([1, 2, 3]), ttl: 8, type: 1);
    expect(tx.sent.length, 1);
    final env = Envelope.fromBytes(tx.sent.first);
    expect(env.ttl, 8);
    expect(env.msgId.length, 16);
  });
}

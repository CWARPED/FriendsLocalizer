import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/envelope.dart';
import 'package:friends_localizer/mesh/config.dart';
import 'package:friends_localizer/mesh/transport.dart';
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/mesh/mesh_engine.dart';

/// Fabrique une trame valide SANS crypto (signature/ciphertext factices) :
/// le moteur ne lit que msgId + ttl, il ne déchiffre pas.
Uint8List buildFrame(Uint8List msgId, int ttl) => Envelope(
      msgId: msgId,
      type: 1,
      ttl: ttl,
      timestampMs: 0,
      senderPub: Uint8List(32),
      ciphertext: Uint8List.fromList([1, 2, 3]),
      signature: Uint8List(64),
    ).toBytes();

Uint8List idBytes(int seed) =>
    Uint8List.fromList(List<int>.generate(16, (i) => (i + seed) & 0xFF));

class RecordingTransport implements MeshTransport {
  final List<Uint8List> sent = [];
  @override
  void send(Uint8List frame) => sent.add(frame);
}

MeshEngine engineWith({
  required VirtualScheduler scheduler,
  required RecordingTransport transport,
  required void Function(Uint8List) onDeliver,
  int suppressionThreshold = 3,
  int backoff = 10,
}) =>
    MeshEngine(
      scheduler: scheduler,
      transport: transport,
      config: MeshConfig(
        suppressionThreshold: suppressionThreshold,
        minBackoffMs: backoff,
        maxBackoffMs: backoff,
        seenTtlMs: 60000,
        storeForwardMs: 30000,
      ),
      random: Random(1),
      onDeliver: onDeliver,
    );

void main() {
  test('originate diffuse la trame et marque comme vue (pas de re-livraison)', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    var delivered = 0;
    final eng = engineWith(scheduler: s, transport: tx, onDeliver: (_) => delivered++);
    final frame = buildFrame(idBytes(1), 8);

    eng.originate(frame);
    expect(tx.sent.length, 1);
    eng.handleInbound(frame);
    expect(delivered, 0);
  });

  test('livre une nouvelle trame une seule fois (déduplication)', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    var delivered = 0;
    final eng = engineWith(scheduler: s, transport: tx, onDeliver: (_) => delivered++);
    final frame = buildFrame(idBytes(2), 8);

    eng.handleInbound(frame);
    eng.handleInbound(frame); // doublon
    expect(delivered, 1);
  });

  test('relaie avec ttl-1 après backoff quand peu de relais entendus', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    final eng = engineWith(scheduler: s, transport: tx, onDeliver: (_) {}, backoff: 10);
    final frame = buildFrame(idBytes(3), 8);

    eng.handleInbound(frame);
    expect(tx.sent, isEmpty);
    s.runUntilIdle();
    expect(tx.sent.length, 1);
    expect(Envelope.fromBytes(tx.sent.first).ttl, 7);
  });

  test('supprime le relais quand assez de doublons sont entendus', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    final eng = engineWith(
        scheduler: s, transport: tx, onDeliver: (_) {},
        suppressionThreshold: 2, backoff: 10);
    final frame = buildFrame(idBytes(4), 8);

    eng.handleInbound(frame);
    eng.handleInbound(frame);
    s.runUntilIdle();
    expect(tx.sent, isEmpty);
  });

  test('ne relaie pas une trame de ttl 1 (mais la livre)', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    var delivered = 0;
    final eng = engineWith(scheduler: s, transport: tx, onDeliver: (_) => delivered++);
    final frame = buildFrame(idBytes(5), 1);

    eng.handleInbound(frame);
    s.runUntilIdle();
    expect(delivered, 1);
    expect(tx.sent, isEmpty);
  });

  test('ignore une trame malformée sans planter', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    var delivered = 0;
    final eng = engineWith(scheduler: s, transport: tx, onDeliver: (_) => delivered++);

    eng.handleInbound(Uint8List.fromList([1, 2, 3]));
    s.runUntilIdle();
    expect(delivered, 0);
    expect(tx.sent, isEmpty);
  });

  test('store-and-forward : re-diffuse une trame bufferisée à l\'apparition d\'un voisin', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    final eng = engineWith(scheduler: s, transport: tx, onDeliver: (_) {});
    final frame = buildFrame(idBytes(10), 1); // ttl 1 : aucun relais automatique

    eng.handleInbound(frame);
    expect(tx.sent, isEmpty); // pas de relais (ttl 1)
    eng.onNeighborAppeared();
    expect(tx.sent.length, 1); // re-diffusée pour le nouveau voisin
    expect(
      Envelope.fromBytes(tx.sent.first).msgId,
      Envelope.fromBytes(frame).msgId,
    );
  });

  test('store-and-forward : n\'expire plus après storeForwardMs', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    final eng = engineWith(scheduler: s, transport: tx, onDeliver: (_) {});
    final frame = buildFrame(idBytes(11), 1);

    eng.handleInbound(frame);
    s.advance(30001); // > storeForwardMs (30000)
    eng.onNeighborAppeared();
    expect(tx.sent, isEmpty); // expirée : non re-diffusée
  });

  test('originate est idempotent (ré-originer le même msgId est ignoré)', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    final eng = engineWith(scheduler: s, transport: tx, onDeliver: (_) {});
    final frame = buildFrame(idBytes(20), 8);

    eng.originate(frame);
    eng.originate(frame); // doit être ignoré
    expect(tx.sent.length, 1);
  });

  test('le buffer store-and-forward est borné à maxStoreFrames', () {
    final s = VirtualScheduler();
    final tx = RecordingTransport();
    final eng = MeshEngine(
      scheduler: s,
      transport: tx,
      config: const MeshConfig(
        suppressionThreshold: 1000,
        minBackoffMs: 10,
        maxBackoffMs: 10,
        seenTtlMs: 60000,
        storeForwardMs: 30000,
        maxStoreFrames: 3,
      ),
      random: Random(1),
      onDeliver: (_) {},
    );
    for (var i = 0; i < 5; i++) {
      eng.handleInbound(buildFrame(idBytes(100 + i), 1));
    }
    s.runUntilIdle();
    tx.sent.clear();
    eng.onNeighborAppeared();
    expect(tx.sent.length, 3);
  });
}

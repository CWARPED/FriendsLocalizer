import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/envelope.dart';
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/server/relay_hub.dart';

Uint8List buildFrame(Uint8List msgId, int ttl) => Envelope(
      msgId: msgId, type: 1, ttl: ttl, timestampMs: 0,
      senderPub: Uint8List(32), ciphertext: Uint8List.fromList([1, 2, 3]),
      signature: Uint8List(64)).toBytes();

Uint8List idBytes(int seed) =>
    Uint8List.fromList(List<int>.generate(16, (i) => (i + seed) & 0xFF));

void main() {
  test('relaie une trame aux autres connexions avec ttl-1, pas à l\'émetteur', () {
    final hub = RelayHub(scheduler: VirtualScheduler());
    final a = <Uint8List>[];
    final b = <Uint8List>[];
    final idA = hub.connect((f) => a.add(f));
    hub.connect((f) => b.add(f));

    hub.ingest(idA, buildFrame(idBytes(1), 8));
    expect(a, isEmpty);
    expect(b.length, 1);
    expect(Envelope.fromBytes(b.first).ttl, 7);
  });

  test('déduplique : le même msgId n\'est relayé qu\'une fois', () {
    final hub = RelayHub(scheduler: VirtualScheduler());
    final b = <Uint8List>[];
    final idA = hub.connect((_) {});
    hub.connect((f) => b.add(f));
    hub.ingest(idA, buildFrame(idBytes(2), 8));
    hub.ingest(idA, buildFrame(idBytes(2), 8));
    expect(b.length, 1);
  });

  test('ne relaie pas une trame de ttl 1', () {
    final hub = RelayHub(scheduler: VirtualScheduler());
    final b = <Uint8List>[];
    final idA = hub.connect((_) {});
    hub.connect((f) => b.add(f));
    hub.ingest(idA, buildFrame(idBytes(3), 1));
    expect(b, isEmpty);
  });

  test('ignore une trame malformée', () {
    final hub = RelayHub(scheduler: VirtualScheduler());
    final b = <Uint8List>[];
    final idA = hub.connect((_) {});
    hub.connect((f) => b.add(f));
    hub.ingest(idA, Uint8List.fromList([1, 2, 3]));
    expect(b, isEmpty);
  });

  test('une connexion déconnectée ne reçoit plus rien', () {
    final hub = RelayHub(scheduler: VirtualScheduler());
    final b = <Uint8List>[];
    final idA = hub.connect((_) {});
    final idB = hub.connect((f) => b.add(f));
    hub.disconnect(idB);
    hub.ingest(idA, buildFrame(idBytes(4), 8));
    expect(b, isEmpty);
    expect(hub.connectionCount, 1);
  });
}

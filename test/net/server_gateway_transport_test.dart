import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:friends_localizer/crypto/envelope.dart';
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/server/server.dart';
import 'package:friends_localizer/server/relay_hub.dart';
import 'package:friends_localizer/server/key_directory.dart';
import 'package:friends_localizer/net/server_gateway_transport.dart';

Uint8List buildFrame(Uint8List msgId, int ttl) => Envelope(
      msgId: msgId, type: 1, ttl: ttl, timestampMs: 0,
      senderPub: Uint8List(32), ciphertext: Uint8List.fromList([1, 2, 3]),
      signature: Uint8List(64)).toBytes();

void main() {
  late dynamic server;
  late int port;

  setUp(() async {
    server = await io.serve(
        buildServer(hub: RelayHub(scheduler: VirtualScheduler()), directory: KeyDirectory()),
        'localhost', 0);
    port = server.port as int;
  });
  tearDown(() async => server.close(force: true));

  test('une trame envoyée par un transport arrive à l\'autre via le relais', () async {
    final a = ServerGatewayTransport('ws://localhost:$port/relay');
    final b = ServerGatewayTransport('ws://localhost:$port/relay');
    final received = <Uint8List>[];
    b.onFrame = (f) => received.add(f);
    await a.start();
    await b.start();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    a.send(buildFrame(Uint8List(16), 8));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(received.length, 1);
    expect(Envelope.fromBytes(received.first).ttl, 7);

    await a.stop();
    await b.stop();
  });

  test('isConnected reflète l\'état de la connexion', () async {
    final t = ServerGatewayTransport('ws://localhost:$port/relay');
    expect(t.isConnected, isFalse);
    await t.start();
    expect(t.isConnected, isTrue);
    await t.stop();
    expect(t.isConnected, isFalse);
  });
}

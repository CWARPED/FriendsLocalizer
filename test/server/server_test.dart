import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as io;
import 'package:web_socket_channel/io.dart';
import 'package:friends_localizer/crypto/envelope.dart';
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/server/server.dart';
import 'package:friends_localizer/server/relay_hub.dart';
import 'package:friends_localizer/server/key_directory.dart';

Uint8List buildFrame(Uint8List msgId, int ttl) => Envelope(
      msgId: msgId, type: 1, ttl: ttl, timestampMs: 0,
      senderPub: Uint8List(32), ciphertext: Uint8List.fromList([1, 2, 3]),
      signature: Uint8List(64)).toBytes();

void main() {
  late dynamic server;
  late int port;
  late RelayHub hub;
  late KeyDirectory dir;

  setUp(() async {
    hub = RelayHub(scheduler: VirtualScheduler());
    dir = KeyDirectory();
    server = await io.serve(buildServer(hub: hub, directory: dir), 'localhost', 0);
    port = server.port as int;
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('GET /health renvoie ok', () async {
    final res = await http.get(Uri.parse('http://localhost:$port/health'));
    expect(res.statusCode, 200);
    expect(res.body, 'ok');
  });

  test('POST /directory puis GET /directory/<group> liste le membre', () async {
    await http.post(
      Uri.parse('http://localhost:$port/directory'),
      body: json.encode({
        'groupId': 'g1', 'memberId': 'a', 'name': 'Alice', 'pub': 'AAAA',
      }),
    );
    final res = await http.get(Uri.parse('http://localhost:$port/directory/g1'));
    expect(res.statusCode, 200);
    final list = json.decode(res.body) as List;
    expect(list.length, 1);
    expect((list.first as Map)['memberId'], 'a');
  });

  test('POST /directory avec un corps invalide renvoie 400', () async {
    final res = await http.post(
      Uri.parse('http://localhost:$port/directory'),
      body: 'pas du json',
    );
    expect(res.statusCode, 400);
  });

  test('relais WebSocket : une trame d\'un client atteint l\'autre (ttl-1)', () async {
    final c1 = IOWebSocketChannel.connect('ws://localhost:$port/relay');
    final c2 = IOWebSocketChannel.connect('ws://localhost:$port/relay');
    await c1.ready;
    await c2.ready;

    final received = c2.stream.first;
    c1.sink.add(buildFrame(Uint8List(16), 8));

    final data = await received.timeout(const Duration(seconds: 3));
    final frame = Uint8List.fromList((data as List).cast<int>());
    expect(Envelope.fromBytes(frame).ttl, 7);

    await c1.sink.close();
    await c2.sink.close();
  });
}

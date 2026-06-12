import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'relay_hub.dart';
import 'key_directory.dart';

/// Construit le handler shelf : /health, /directory (REST), /relay (WebSocket).
/// Le serveur ne déchiffre rien ; il relaie des trames opaques et sert un
/// annuaire de données publiques.
Handler buildServer({required RelayHub hub, required KeyDirectory directory}) {
  final router = Router();

  router.get('/health', (Request req) => Response.ok('ok'));

  router.post('/directory', (Request req) async {
    try {
      final body = await req.readAsString();
      final entry =
          MemberEntry.fromJson(json.decode(body) as Map<String, dynamic>);
      directory.publish(entry);
      return Response.ok('ok');
    } catch (_) {
      return Response(400, body: 'invalid body');
    }
  });

  router.get('/directory/<groupId>', (Request req, String groupId) {
    final list = directory.roster(groupId).map((e) => e.toJson()).toList();
    return Response.ok(json.encode(list),
        headers: {'content-type': 'application/json'});
  });

  router.get(
    '/relay',
    webSocketHandler((WebSocketChannel channel, String? protocol) {
      final connId = hub.connect((frame) => channel.sink.add(frame));
      channel.stream.listen(
        (data) {
          if (data is List<int>) hub.ingest(connId, Uint8List.fromList(data));
        },
        onDone: () => hub.disconnect(connId),
        onError: (_) => hub.disconnect(connId),
      );
    }),
  );

  return router.call;
}

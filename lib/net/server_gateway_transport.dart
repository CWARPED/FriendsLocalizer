import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../mesh/transport.dart';

/// Transport mesh par WebSocket vers le serveur relais (Plan 5).
/// `send` pousse la trame binaire ; les trames entrantes vont à [onFrame].
class ServerGatewayTransport implements MeshTransport {
  final String url;
  WebSocketChannel? _channel;

  void Function(Uint8List frame)? onFrame;
  void Function()? onNeighbor;

  ServerGatewayTransport(this.url);

  /// Vrai tant qu'une connexion est ouverte (sert au mode festival pour décider
  /// de se reconnecter en arrière-plan).
  bool get isConnected => _channel != null;

  Future<void> start() async {
    await _channel?.sink.close();
    final channel = IOWebSocketChannel.connect(Uri.parse(url));
    await channel.ready;
    _channel = channel;
    onNeighbor?.call();
    channel.stream.listen(
      (data) {
        if (data is List<int>) onFrame?.call(Uint8List.fromList(data));
      },
      onError: (_) {},
      onDone: () {},
    );
  }

  Future<void> stop() async {
    await _channel?.sink.close();
    _channel = null;
  }

  @override
  void send(Uint8List frame) {
    _channel?.sink.add(frame);
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../mesh/transport.dart';

/// Transport mesh par WebSocket vers le serveur relais (Plan 5).
/// `send` pousse la trame binaire ; les trames entrantes vont à [onFrame].
///
/// Auto-reconnectant : si la connexion tombe (changement Wi-Fi/4G, NAT coupé,
/// relais redémarré), il se rebranche tout seul avec un backoff. Un ping
/// régulier garde la ligne au chaud (sinon les NAT/pare-feux effacent la route
/// en silence et le relais ne peut plus nous joindre).
class ServerGatewayTransport implements MeshTransport {
  final String url;
  WebSocketChannel? _channel;
  bool _wantConnected = false; // false après stop() : ne pas se reconnecter
  Timer? _reconnectTimer;
  int _backoffMs = 1000;

  /// Intervalle de ping (battement de cœur).
  static const Duration _pingInterval = Duration(seconds: 25);
  static const int _maxBackoffMs = 30000;

  void Function(Uint8List frame)? onFrame;
  void Function()? onNeighbor;

  ServerGatewayTransport(this.url);

  /// Vrai tant qu'une connexion est ouverte.
  bool get isConnected => _channel != null;

  Future<void> start() async {
    _wantConnected = true;
    _reconnectTimer?.cancel();
    await _connect();
  }

  Future<void> _connect() async {
    await _channel?.sink.close();
    _channel = null;
    final channel = IOWebSocketChannel.connect(
      Uri.parse(url),
      pingInterval: _pingInterval,
    );
    try {
      await channel.ready;
    } catch (_) {
      // relais injoignable pour l'instant : on retentera (backoff).
      _scheduleReconnect();
      return;
    }
    _channel = channel;
    _backoffMs = 1000; // reset du backoff après une connexion réussie
    onNeighbor?.call();
    channel.stream.listen(
      (data) {
        if (data is List<int>) onFrame?.call(Uint8List.fromList(data));
      },
      onError: (_) => _onClosed(),
      onDone: () => _onClosed(),
      cancelOnError: true,
    );
  }

  void _onClosed() {
    _channel = null;
    if (_wantConnected) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = _backoffMs;
    _backoffMs = (_backoffMs * 2).clamp(1000, _maxBackoffMs);
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (_wantConnected) _connect();
    });
  }

  Future<void> stop() async {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channel?.sink.close();
    _channel = null;
  }

  @override
  void send(Uint8List frame) {
    _channel?.sink.add(frame);
  }
}

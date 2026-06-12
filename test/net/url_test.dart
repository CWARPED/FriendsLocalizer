import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/net/url.dart';

void main() {
  test('ws->http et /relay retiré', () {
    expect(directoryBaseFromWs('ws://host:8080/relay'), 'http://host:8080');
    expect(directoryBaseFromWs('wss://host:8080'), 'https://host:8080');
    expect(directoryBaseFromWs('ws://host:8080'), 'http://host:8080');
  });

  test('relayWsUrl ajoute /relay si absent (idempotent)', () {
    expect(relayWsUrl('ws://host:8080'), 'ws://host:8080/relay');
    expect(relayWsUrl('ws://host:8080/'), 'ws://host:8080/relay');
    expect(relayWsUrl('ws://host:8080/relay'), 'ws://host:8080/relay');
    expect(relayWsUrl('  ws://host:8080  '), 'ws://host:8080/relay');
  });
}

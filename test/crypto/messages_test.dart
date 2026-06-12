import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/messages.dart';

void main() {
  test('LocationRequest encode/decode round-trip', () {
    final req = LocationRequest(
      requestId: 'req-123',
      targetId: 'alice',     // '*' = tout le groupe
      live: false,
    );
    final back = LocationRequest.decode(req.encode());
    expect(back.requestId, 'req-123');
    expect(back.targetId, 'alice');
    expect(back.live, isFalse);
  });

  test('encode lève si un identifiant dépasse 255 octets', () {
    final longId = 'a' * 256;
    final req = LocationRequest(requestId: longId, targetId: 'x', live: false);
    expect(() => req.encode(), throwsArgumentError);
  });

  test('LocationResponse encode/decode round-trip', () {
    final res = LocationResponse(
      requestId: 'req-123',
      responderId: 'alice',
      latitude: 48.8566,
      longitude: 2.3522,
      accuracyMeters: 12.5,
      timestampMs: 1700000000000,
    );
    final back = LocationResponse.decode(res.encode());
    expect(back.requestId, 'req-123');
    expect(back.responderId, 'alice');
    expect(back.latitude, closeTo(48.8566, 1e-6));
    expect(back.longitude, closeTo(2.3522, 1e-6));
    expect(back.accuracyMeters, closeTo(12.5, 1e-3));
    expect(back.timestampMs, 1700000000000);
  });
}

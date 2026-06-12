import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/radar.dart';

void main() {
  test('kSessionDurationMs = 5 min', () {
    expect(kSessionDurationMs, 5 * 60 * 1000);
  });

  test('sessionRemainingSeconds : plein, écoulé, négatif', () {
    expect(sessionRemainingSeconds(300000, 0), 300);
    expect(sessionRemainingSeconds(1000, 1000), 0);
    expect(sessionRemainingSeconds(0, 5000), 0); // jamais négatif
  });
}

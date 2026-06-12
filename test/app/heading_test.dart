import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/heading.dart';

void main() {
  test('précision inconnue ou négative -> unknown', () {
    expect(reliabilityFor(null), HeadingReliability.unknown);
    expect(reliabilityFor(-1), HeadingReliability.unknown);
  });

  test('petite marge -> good, grande marge -> low', () {
    expect(reliabilityFor(5), HeadingReliability.good);
    expect(reliabilityFor(20), HeadingReliability.good);
    expect(reliabilityFor(45), HeadingReliability.low);
  });

  test('HeadingReading expose sa fiabilité', () {
    expect(const HeadingReading(90, accuracyDegrees: 5).reliability,
        HeadingReliability.good);
    expect(const HeadingReading(90).reliability, HeadingReliability.unknown);
  });
}

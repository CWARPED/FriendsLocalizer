import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/heading.dart';
import 'package:friends_localizer/app/heading_providers.dart';

void main() {
  test('NullHeadingProvider n\'émet rien', () async {
    expect(await const NullHeadingProvider().readings().isEmpty, isTrue);
  });

  test('StreamHeadingProvider lisse la source et conserve la précision',
      () async {
    final source = Stream<HeadingReading>.fromIterable(const [
      HeadingReading(350, accuracyDegrees: 5),
      HeadingReading(10, accuracyDegrees: 5),
    ]);
    final out =
        await StreamHeadingProvider(source, alpha: 0.5).readings().toList();
    expect(out[0].degrees, closeTo(350, 0.001));
    expect(out[1].degrees, closeTo(0, 0.001)); // lissé à travers 0
    expect(out[1].accuracyDegrees, 5);
  });
}

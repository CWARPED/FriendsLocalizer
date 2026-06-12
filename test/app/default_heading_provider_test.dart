import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/app/heading_providers.dart';
import 'package:friends_localizer/app/compass_heading_provider.dart';

void main() {
  test('hors mobile (desktop/test) -> NullHeadingProvider', () {
    // La suite tourne sur l'hôte (Windows) : pas de boussole -> repli Null.
    expect(defaultHeadingProvider(), isA<NullHeadingProvider>());
  });
}

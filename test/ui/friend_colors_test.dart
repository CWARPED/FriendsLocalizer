import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/friend_colors.dart';

void main() {
  test('même id => même couleur (stable)', () {
    expect(colorForMember('tom00'), colorForMember('tom00'));
  });

  test('la couleur fait partie de la palette', () {
    expect(kFriendColors.contains(colorForMember('ana00')), isTrue);
  });

  test('des ids différents ne tombent pas tous sur la même couleur', () {
    final colors = {
      for (final id in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'])
        colorForMember(id)
    };
    expect(colors.length, greaterThan(1));
  });
}

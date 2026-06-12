import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/friend_colors.dart';
import 'package:friends_localizer/ui/widgets/friend_dot.dart';

void main() {
  testWidgets('FriendDot utilise la couleur du membre', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FriendDot('tom00'))));
    final box = tester.widget<Container>(find.byType(Container));
    final deco = box.decoration as BoxDecoration;
    expect(deco.color, colorForMember('tom00'));
  });
}

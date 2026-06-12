import 'package:flutter/material.dart';
import '../friend_colors.dart';

/// Pastille de couleur arrondie identifiant un membre.
class FriendDot extends StatelessWidget {
  final String memberId;
  final double size;
  const FriendDot(this.memberId, {this.size = 24, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorForMember(memberId),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
    );
  }
}

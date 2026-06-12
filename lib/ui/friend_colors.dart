import 'package:flutter/material.dart';

/// Palette douce assignée aux membres (pas de RGB franc).
const List<Color> kFriendColors = [
  Color(0xFFE8927C), // coral
  Color(0xFF6FB3A8), // teal
  Color(0xFF8AA0D8), // périwinkle
  Color(0xFFE0B36A), // ambre
  Color(0xFFB79CE8), // lavande
  Color(0xFF9CC4A0), // sauge
  Color(0xFFDDA0B4), // rose
  Color(0xFF7FB0C9), // bleu-gris
];

/// Couleur déterministe et stable pour un [memberId].
Color colorForMember(String memberId) {
  var h = 0;
  for (final c in memberId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return kFriendColors[h % kFriendColors.length];
}

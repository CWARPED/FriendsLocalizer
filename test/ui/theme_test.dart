import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/theme.dart';

void main() {
  test('thème sombre : brightness + jetons', () {
    final t = buildDarkTheme();
    expect(t.brightness, Brightness.dark);
    final p = t.extension<AppPalette>()!;
    expect(p.screen, const Color(0xFF0F1320));
    expect(p.card, const Color(0xFF1B2032));
    expect(p.accent, const Color(0xFF4A5A8F));
  });

  test('thème clair : brightness + jetons', () {
    final t = buildLightTheme();
    expect(t.brightness, Brightness.light);
    final p = t.extension<AppPalette>()!;
    expect(p.screen, const Color(0xFFFBFCFE));
    expect(p.textPrimary, const Color(0xFF2B3040));
  });

  test('lerp(t=0) renvoie la première palette', () {
    final a = buildDarkTheme().extension<AppPalette>()!;
    final b = buildLightTheme().extension<AppPalette>()!;
    expect(a.lerp(b, 0).screen, a.screen);
  });
}

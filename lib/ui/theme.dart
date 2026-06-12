import 'package:flutter/material.dart';

/// Jetons de couleur custom (au-delà du ColorScheme Material).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color screen;
  final Color card;
  final Color inset;
  final Color raised;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color radarFace;
  final Color radarRing;
  final Color radarMark;

  const AppPalette({
    required this.screen,
    required this.card,
    required this.inset,
    required this.raised,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.radarFace,
    required this.radarRing,
    required this.radarMark,
  });

  @override
  AppPalette copyWith({
    Color? screen,
    Color? card,
    Color? inset,
    Color? raised,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? accent,
    Color? accentSoft,
    Color? radarFace,
    Color? radarRing,
    Color? radarMark,
  }) =>
      AppPalette(
        screen: screen ?? this.screen,
        card: card ?? this.card,
        inset: inset ?? this.inset,
        raised: raised ?? this.raised,
        border: border ?? this.border,
        textPrimary: textPrimary ?? this.textPrimary,
        textMuted: textMuted ?? this.textMuted,
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        radarFace: radarFace ?? this.radarFace,
        radarRing: radarRing ?? this.radarRing,
        radarMark: radarMark ?? this.radarMark,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      screen: l(screen, other.screen),
      card: l(card, other.card),
      inset: l(inset, other.inset),
      raised: l(raised, other.raised),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      radarFace: l(radarFace, other.radarFace),
      radarRing: l(radarRing, other.radarRing),
      radarMark: l(radarMark, other.radarMark),
    );
  }
}

const _darkPalette = AppPalette(
  screen: Color(0xFF0F1320),
  card: Color(0xFF1B2032),
  inset: Color(0xFF11151F),
  raised: Color(0xFF26314D),
  border: Color(0xFF2A3046),
  textPrimary: Color(0xFFE6E9F5),
  textMuted: Color(0xFF8A90A8),
  accent: Color(0xFF4A5A8F),
  accentSoft: Color(0xFFAEBFE8),
  radarFace: Color(0xFF121826),
  radarRing: Color(0xFF232B3E),
  radarMark: Color(0xFFDFE3EF),
);

const _lightPalette = AppPalette(
  screen: Color(0xFFFBFCFE),
  card: Color(0xFFF1F4FB),
  inset: Color(0xFFEEF1F8),
  raised: Color(0xFFE6EAF4),
  border: Color(0xFFD3D8E6),
  textPrimary: Color(0xFF2B3040),
  textMuted: Color(0xFF97A0B5),
  accent: Color(0xFF6F8BD0),
  accentSoft: Color(0xFF5F6B86),
  radarFace: Color(0xFFF7F9FD),
  radarRing: Color(0xFFDDE3F0),
  radarMark: Color(0xFF46506B),
);

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkPalette.screen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _darkPalette.accent,
        brightness: Brightness.dark,
      ),
      extensions: const [_darkPalette],
    );

ThemeData buildLightTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightPalette.screen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightPalette.accent,
        brightness: Brightness.light,
      ),
      extensions: const [_lightPalette],
    );

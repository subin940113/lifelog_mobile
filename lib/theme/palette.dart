import 'package:flutter/material.dart';

class Palette {
  final Color bg; // page background
  final Color surface; // subtle surface (sheet/pills)
  final Color ink; // primary text
  final Color muted; // secondary text
  final Color outline; // hairline border
  final Color accent; // single accent (links / primary action)
  final Color accentSoft;

  // 🔴 Danger (destructive actions only)
  final Color danger;
  final Color dangerSoft;

  const Palette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.outline,
    required this.accent,
    required this.accentSoft,
    required this.danger,
    required this.dangerSoft,
  });

  Color get card => surface;
  Color get inkSoft => accentSoft;

  static Palette light() => Palette.from(const ColorScheme.light());
  static Palette dark() => Palette.from(const ColorScheme.dark());

  factory Palette.from(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    if (isDark) {
      return const Palette(
        // Base background: cooler, deeper charcoal
        bg: Color(0xFF212024),

        // Surface slightly lifted from bg for cards/sheets
        surface: Color(0xFF2A2930),

        // Primary text: soft white with reduced glare
        ink: Color(0xFFECECF0),

        // Secondary text: cooler gray
        muted: Color(0xFFB2B1B8),

        // Hairline borders: subtle contrast against bg/surface
        outline: Color(0xFF3A3942),

        // Brand accent remains consistent
        accent: Color(0xFF2E6BE6),

        // Soft accent adapted for dark background
        accentSoft: Color(0xFF1F2F52),

        // Danger colors slightly cooled for dark mode
        danger: Color(0xFFD14A4A),
        dangerSoft: Color(0xFF4A2628),
      );
    }

    // Light: 기존 그대로
    return const Palette(
      bg: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF2B2B2B),
      muted: Color(0xFF8A8A8A),
      outline: Color(0xFFE6E3DC),
      accent: Color(0xFF2E6BE6),
      accentSoft: Color(0xFFE9F0FF),
      danger: Color(0xFFD64545),
      dangerSoft: Color(0xFFFFE9E9),
    );
  }
}

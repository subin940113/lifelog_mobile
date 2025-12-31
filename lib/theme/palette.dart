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

  /// Compatibility with earlier code
  Color get card => surface;
  Color get inkSoft => accentSoft;

  /// Convenience helpers
  static Palette light() => Palette.from(const ColorScheme.light());
  static Palette dark() => Palette.from(const ColorScheme.dark());

  factory Palette.from(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    if (isDark) {
      // Dark: muted, wine-like red (not neon, not alarmist)
      return const Palette(
        bg: Color(0xFF121212),
        surface: Color(0xFF171717),
        ink: Color(0xFFEAEAEA),
        muted: Color(0xFF9B9B9B),
        outline: Color(0xFF2A2A2A),
        accent: Color(0xFF2E6BE6),
        accentSoft: Color(0xFFE9F0FF),

        // 🔴 danger
        danger: Color(0xFFCF3F3F),     // deep muted red
        dangerSoft: Color(0xFFFFE8E8), // very soft red tint
      );
    }

    // Light: calm brick-red (서비스 톤 유지)
    return const Palette(
      bg: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF2B2B2B),
      muted: Color(0xFF8A8A8A),
      outline: Color(0xFFE6E3DC),
      accent: Color(0xFF2E6BE6),
      accentSoft: Color(0xFFE9F0FF),

      // 🔴 danger
      danger: Color(0xFFD64545),     // warm brick red
      dangerSoft: Color(0xFFFFE9E9), // paper-like red tint
    );
  }
}
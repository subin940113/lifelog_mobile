import 'package:flutter/material.dart';

class Palette {
  final Color bg; // page background
  final Color surface; // subtle surface (sheet/pills)
  final Color ink; // primary text
  final Color muted; // secondary text
  final Color outline; // hairline border
  final Color accent; // single accent (links)
  final Color accentSoft;

  const Palette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.outline,
    required this.accent,
    required this.accentSoft,
  });

  /// Compatibility with earlier code (settings sheet uses p.card / p.inkSoft)
  Color get card => surface;
  Color get inkSoft => accentSoft;

  /// Convenience helpers (optional, but helps older call sites compile)
  static Palette light() => Palette.from(const ColorScheme.light());
  static Palette dark() => Palette.from(const ColorScheme.dark());

  factory Palette.from(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    if (isDark) {
      // Dark: not pure black (still “blog-like”)
      return const Palette(
        bg: Color(0xFF121212),
        surface: Color(0xFF171717),
        ink: Color(0xFFEAEAEA),
        muted: Color(0xFF9B9B9B),
        outline: Color(0xFF2A2A2A),
        accent: Color(0xFF2E6BE6),
        accentSoft: Color(0xFFE9F0FF),
      );
    }

    // Light: warm, paper-like but not yellow
    return const Palette(
      bg: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF2B2B2B), // softer than pure black
      muted: Color(0xFF8A8A8A),
      outline: Color(0xFFE6E3DC),
      accent: Color(0xFF2E6BE6), // single blue
      accentSoft: Color(0xFFE9F0FF),
    );
  }
}

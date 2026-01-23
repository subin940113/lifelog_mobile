import 'package:flutter/material.dart';

class Palette {
   static const Color strokeLight = Color(0xFF2B2F36);
  static const Color strokeDark  = Color(0xFF8EC7FF);
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
        // Base background
        bg: Color(0xFF212024),
        surface: Color(0xFF2A2930),

        // Text
        ink: Color(0xFFECECF0),
        muted: Color(0xFFB2B1B8),

        // Slightly bluish hairline to harmonize with sky strokes
        outline: Color(0xFF2E3A4A),

        // Match wave/object outline tone used across the app
        accent: Color(0xFF8EC7FF),

        // Deep night-sky wash
        accentSoft: Color(0xFF1A2A3D),

        // Danger
        danger: Color(0xFFD14A4A),
        dangerSoft: Color(0xFF4A2628),
      );
    }

    // ☀️ Light: Pointy Cute Sky Blue (화이트에서 확실히 보이게)
    return const Palette(
      bg: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),

      // Text (slightly cool to match the blue system)
      ink: Color(0xFF22262C),
      muted: Color(0xFF6E7A88),

      // Hairline border: very light sky tint (avoid beige)
      outline: Color(0xFFDCEBFA),

      // Sky‑blue accent for interactions (light, airy)
      accent: Color(0xFF3FA6F3),

      // Soft sky wash
      accentSoft: Color(0xFFE1F1FF),

      danger: Color(0xFFD64545),
      dangerSoft: Color(0xFFFFE9E9),
    );
  }
}
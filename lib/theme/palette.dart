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
        // Base background: cool dark
        bg: Color(0xFF212024),

        // Surface lifted
        surface: Color(0xFF2A2930),

        // Text
        ink: Color(0xFFECECF0),

        // ✅ muted: cooler gray (노란기 제거)
        muted: Color(0xFFB6B9C2),

        // ✅ outline: cool hairline (과한 대비 없이 차갑게)
        outline: Color(0xFF3B3E49),

        // ✅ accent: cold sky / azure (포인트 강함)
        accent: Color(0xFF5AAEFF),

        // ✅ accentSoft: dark 배경에서 선택/배지 배경으로 확실히 보이게
        accentSoft: Color(0xFF223B5A),

        // Danger
        danger: Color(0xFFD14A4A),
        dangerSoft: Color(0xFF4A2628),
      );
    }

    return const Palette(
      bg: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),

      // Text
      ink: Color(0xFF2B2B2B),

      // ✅ muted: warm gray → cool gray로 교체 (UI가 더 차분/차가워짐)
      muted: Color(0xFF7F8796),

      // ✅ outline: 베이지톤 제거, 살짝 쿨한 회색으로
      // 기존(E6E3DC)은 따뜻해서 하늘색과 충돌/탁해보일 수 있음
      outline: Color(0xFFE3E8F0),

      // ✅ accent: 차가운 하늘색(아주르) + 충분히 진하게(포인트)
      // white 배경에서 "버튼/링크 포인트"가 확실히 읽히는 값
      accent: Color(0xFF3F96FF),

      // ✅ accentSoft: accent hue 유지 + 선택/배경에서 티 나게
      // 너무 하얗지 않게 해서 '존재감' 확보
      accentSoft: Color(0xFFE6F1FF),

      // Danger
      danger: Color(0xFFD64545),
      dangerSoft: Color(0xFFFFE9E9),
    );
  }
}

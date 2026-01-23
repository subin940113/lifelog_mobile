import 'dart:math' as math;
import 'package:flutter/material.dart';

/// WatercolorFab
/// - Signal Object와 동일한 수채화 질감 언어
/// - 애니메이션 없음 (정적)
/// - 버튼이지만 UI 버튼처럼 튀지 않음
/// - 원형 오브젝트 형태
class WatercolorFab extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const WatercolorFab({
    super.key,
    required this.onTap,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _WatercolorFabPainter(
            isDark: isDark,
          ),

          // ⚠️ 아이콘은 선택 사항
          // 완전히 제거하면 더 추상적인 “알” 느낌
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              size: 26,
              color: Color(0xFF224D86),
            ),
          ),
        ),
      ),
    );
  }
}

class _WatercolorFabPainter extends CustomPainter {
  final bool isDark;

  _WatercolorFabPainter({
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w * 0.46;

    final rect = Rect.fromLTWH(0, 0, w, h);

    // ===== Fill: 수채화 워시 =====
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.30),
        radius: 1.12,
        colors: [
          const Color(0xFFD6F3FF).withOpacity(isDark ? 0.92 : 1.0),
          const Color(0xFF9AD8FA).withOpacity(0.90),
          const Color(0xFFF7FDFF).withOpacity(0.98),
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, r, fillPaint);

    // ===== 아주 미세한 수채 질감 (grain) =====
    final tex = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 10; i++) {
      final a = i * 0.9;
      final dx = center.dx + math.cos(a) * r * 0.45;
      final dy = center.dy + math.sin(a * 1.15) * r * 0.42;

      tex.color = Colors.white.withOpacity(0.03);
      canvas.drawCircle(
        Offset(dx, dy),
        2.2,
        tex,
      );
    }

    // ===== Outline =====
    final outlineColor = isDark
        ? const Color(0xFF8EC7FF)
        : const Color(0xFF224D86);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 2.8 : 1.4
      ..color = outlineColor.withOpacity(isDark ? 0.9 : 0.7);

    canvas.drawCircle(center, r, strokePaint);

    // ===== Inner highlight =====
    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Colors.white.withOpacity(isDark ? 0.22 : 0.16);

    canvas.drawCircle(center, r * 0.985, innerStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
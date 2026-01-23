// lib/widgets/signal_style_button.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// 시그널 오브젝트와 동일한 디자인의 버튼
class SignalStyleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Palette p;

  /// Optional custom icon widget (e.g. SoftCheckIcon).
  /// If provided, [icon] is ignored.
  final Widget? iconWidget;

  final IconData icon;
  final double size;

  const SignalStyleButton({
    super.key,
    required this.onTap,
    required this.p,
    required this.icon,
    this.iconWidget,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const outlineLight = Palette.strokeLight;
    const outlineDark = Palette.strokeDark;
    final outlineColor = isDark ? outlineDark : outlineLight;
    final iconColor = outlineColor.withOpacity(isDark ? 0.88 : 0.68);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _SignalButtonPainter(isDark: isDark),
            ),
            if (iconWidget != null)
              SizedBox(
                width: size * 0.52,
                height: size * 0.52,
                child: Center(child: iconWidget!),
              )
            else
              Icon(icon, color: iconColor, size: size * 0.5),
          ],
        ),
      ),
    );
  }
}

class _SignalButtonPainter extends CustomPainter {
  final bool isDark;

  _SignalButtonPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final baseR = (w < h ? w : h) * 0.46;

    // 정적인 blob 형태 (애니메이션 없음)
    final path = Path();
    const steps = 96;
    const t = 0.0; // 고정값

    for (int i = 0; i <= steps; i++) {
      final a = (i / steps) * 2 * math.pi;

      final k1 = math.sin(a * 2.0 + t * 2 * math.pi);
      final k2 = math.sin(a * 3.0 - t * 2 * math.pi * 0.7);
      final k3 = math.sin(a * 5.0 + t * 2 * math.pi * 0.35);

      final r = baseR * (1.0 + 0.030 * (0.55 * k1 + 0.30 * k2 + 0.15 * k3));

      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    const outlineLight = Palette.strokeLight;
    const outlineDark = Palette.strokeDark;

    const cTop0 = Color(0xFFD6F3FF);
    const cMid0 = Color(0xFF9AD8FA);
    const cBot0 = Color(0xFFF7FDFF);

    Color lift(Color c, double amt) => Color.lerp(c, Colors.white, amt)!;

    final outline = isDark ? outlineDark : outlineLight;

    final cTop = isDark ? lift(cTop0, 0.10) : cTop0;
    final cMid = isDark ? lift(cMid0, 0.08) : cMid0;
    final cBot = isDark ? lift(cBot0, 0.06) : cBot0;

    final rect = Rect.fromLTWH(0, 0, w, h);
    final rot = math.pi; // ~180deg

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.24, -0.30),
        radius: 1.06,
        colors: <Color>[
          cTop.withOpacity(0.985),
          cMid.withOpacity(0.905),
          cBot.withOpacity(0.985),
        ],
        stops: const <double>[0.0, 0.46, 1.0],
        transform: GradientRotation(rot),
      ).createShader(rect);

    final overlayPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: const Alignment(-0.70, -0.55),
        end: const Alignment(0.75, 0.85),
        transform: GradientRotation(rot),
        colors: <Color>[
          Colors.white.withOpacity(0.12),
          const Color(0xFF79BDEB).withOpacity(0.095),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(rect);

    final vignettePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(0.05, -0.12),
        radius: 1.25,
        colors: <Color>[
          Colors.transparent,
          const Color(0xFF6FB3E3).withOpacity(0.030),
        ],
        stops: const <double>[0.70, 1.0],
        transform: GradientRotation(rot),
      ).createShader(rect);

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, overlayPaint);
    canvas.drawPath(path, vignettePaint);

    // 텍스처 효과
    final tex = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final a = (i * 0.92) % (2 * math.pi);
      final rr = baseR * (0.16 + 0.48 * ((i % 5) / 5.0));
      final dx = math.cos(a) * rr * 0.55;
      final dy = math.sin(a * 1.12) * rr * 0.45;

      final rDot = 2.6 + (i % 4) * 1.1;
      final o = 0.020 + (i % 3) * 0.008;

      tex.color = (i.isEven ? Colors.white : const Color(0xFF8BC9F3))
          .withOpacity(o);
      canvas.drawCircle(Offset(center.dx + dx, center.dy + dy), rDot, tex);
    }

    // 외부 테두리
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 3.0 : 1.4
      ..color = outline.withOpacity(isDark ? 0.88 : 0.68);
    canvas.drawPath(path, strokePaint);

    // 내부 테두리
    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = Colors.white.withOpacity(isDark ? 0.22 : 0.16);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(0.988, 0.988);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, innerStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SignalButtonPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

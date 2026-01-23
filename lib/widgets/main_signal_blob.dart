import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// Main-page style watercolor blob + floating word inside.
///
/// Usage:
///   Stack(
///     alignment: Alignment.center,
///     children: [
///       MainSignalBlob(t: t, size: 252, hasSignal: false),
///       Positioned.fill(
///         child: IgnorePointer(
///           child: FloatingWordInBlob(
///             t: t,
///             word: 'bluelog',
///           ),
///         ),
///       ),
///     ],
///   )
class MainSignalBlob extends StatelessWidget {
  final double t; // 0..1
  final double size;
  final bool hasSignal;

  const MainSignalBlob({
    super.key,
    required this.t,
    required this.size,
    required this.hasSignal,
  });

  @override
  Widget build(BuildContext context) {
    // Always use light-mode stroke colors (no dark-mode branching).
    const stroke = Palette.strokeLight;

    return SizedBox(
      width: size,
      height: size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _MainBlobPainter(
            accent: stroke,
            t: t,
            hasSignal: hasSignal,
            stroke: stroke,
            isDark: false,
          ),
        ),
      ),
    );
  }
}

class _MainBlobPainter extends CustomPainter {
  final Color accent;
  final double t;
  final bool hasSignal;
  final Color stroke;
  final bool isDark;

  _MainBlobPainter({
    required this.accent,
    required this.t,
    required this.hasSignal,
    required this.stroke,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final baseR = (w < h ? w : h) * 0.46;

    final wobble = 0.045 + (hasSignal ? 0.016 : 0.0);
    final phase = t * 2 * math.pi;

    final bulgeAmp = 0.035 + (hasSignal ? 0.014 : 0.0);
    final bulgeAngle = phase * 0.85 + 0.6;

    final path = Path();
    const steps = 96;
    for (int i = 0; i <= steps; i++) {
      final a = (i / steps) * 2 * math.pi;

      final k1 = math.sin(a * 2.0 + phase);
      final k2 = math.sin(a * 3.0 - phase * 0.7);
      final k3 = math.sin(a * 5.0 + phase * 0.35);

      final d = _wrapAngle(a - bulgeAngle);
      final bulge = math.exp(-(d * d) / 0.55) * bulgeAmp;

      final r =
          baseR * (1.0 + wobble * (0.55 * k1 + 0.30 * k2 + 0.15 * k3) + bulge);

      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    const cTop = Color(0xFFD6F3FF);
    const cMid = Color(0xFF9AD8FA);
    const cBot = Color(0xFFF7FDFF);

    final rect = Rect.fromLTWH(0, 0, w, h);
    final rot = 180.0 * math.pi / 180.0;

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

    // --- Watercolor texture (paper grain + soft blotches) ---
    final softBlotch = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.8);

    for (int i = 0; i < 9; i++) {
      final a = (i * 1.06 + t * 3.2) % (2 * math.pi);
      final rr = baseR * (0.16 + 0.48 * (i / 9.0));
      final dx = math.cos(a) * rr * 0.64;
      final dy = math.sin(a * 1.02) * rr * 0.52;

      final bias = (dx < 0 && dy < 0) ? 1.35 : 1.0;

      softBlotch.color = const Color(0xFF66B4E6).withOpacity(0.026 * bias);
      canvas.drawCircle(
        Offset(center.dx + dx, center.dy + dy),
        10.5 + i * 2.7,
        softBlotch,
      );

      softBlotch.color = Colors.white.withOpacity(0.022);
      canvas.drawCircle(
        Offset(center.dx + dx * 0.86, center.dy + dy * 0.86),
        8.6 + i * 2.1,
        softBlotch,
      );
    }

    double _hash01(double x) {
      final s = math.sin(x) * 43758.5453123;
      return s - s.floor();
    }

    canvas.save();
    canvas.clipPath(path);

    final grain = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 110; i++) {
      final u = _hash01(i * 12.9898 + t * 7.3);
      final v = _hash01(i * 78.233 + t * 5.1);

      final ang = u * 2 * math.pi;
      final rad = math.sqrt(v) * baseR * 0.92;
      final x = center.dx + math.cos(ang) * rad;
      final y = center.dy + math.sin(ang) * rad;

      final rDot = 0.8 + _hash01(i * 3.17 + t * 2.1) * 1.6;
      final o = 0.010 + _hash01(i * 9.91 + t * 4.2) * 0.020;

      grain.color = const Color(0xFF78BDEB).withOpacity(o);
      canvas.drawCircle(Offset(x, y), rDot, grain);
    }

    for (int i = 0; i < 75; i++) {
      final u = _hash01(i * 5.398 + t * 6.7);
      final v = _hash01(i * 41.135 + t * 3.9);

      final ang = u * 2 * math.pi;
      final rad = math.sqrt(v) * baseR * 0.95;
      final x = center.dx + math.cos(ang) * rad;
      final y = center.dy + math.sin(ang) * rad;

      final rDot = 0.7 + _hash01(i * 1.77 + t * 1.6) * 1.4;
      final o = 0.010 + _hash01(i * 8.61 + t * 2.8) * 0.018;

      grain.color = Colors.white.withOpacity(o);
      canvas.drawCircle(Offset(x, y), rDot, grain);
    }

    canvas.restore();

    final tex = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 16; i++) {
      final a = (i * 0.83 + t * 5.9) % (2 * math.pi);
      final rr = baseR * (0.16 + 0.52 * ((i % 6) / 6.0));
      final dx = math.cos(a) * rr * 0.58;
      final dy = math.sin(a * 1.08) * rr * 0.48;

      final rDot = 2.0 + (i % 5) * 1.15;
      final o = 0.024 + (i % 4) * 0.010;

      tex.color = (i.isEven ? Colors.white : const Color(0xFF78BDEB))
          .withOpacity(o.clamp(0.0, 0.06));
      canvas.drawCircle(Offset(center.dx + dx, center.dy + dy), rDot, tex);
    }

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.12
      ..color = stroke.withOpacity(isDark ? 0.74 : 0.62);
    canvas.drawPath(path, strokePaint);

    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = Colors.white.withOpacity(isDark ? 0.18 : 0.14);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(0.988, 0.988);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, innerStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MainBlobPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.accent.value != accent.value ||
        oldDelegate.hasSignal != hasSignal ||
        oldDelegate.stroke.value != stroke.value ||
        oldDelegate.isDark != isDark;
  }

  double _wrapAngle(double a) {
    var x = a;
    while (x > math.pi) x -= 2 * math.pi;
    while (x < -math.pi) x += 2 * math.pi;
    return x;
  }
}

/// Public (non-underscore) so it can be used from multiple screens.
class FloatingWordInBlob extends StatelessWidget {
  final double t; // 0..1
  final String word;
  final Color? color;

  const FloatingWordInBlob({
    super.key,
    required this.t,
    required this.word,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Always use light-mode stroke colors (no dark-mode branching).
    final baseColor = color ?? Palette.strokeLight;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final center = Offset(w / 2, h / 2);

        final rBase = (w < h ? w : h) * 0.29;

        final letters = word.split('');
        final n = letters.length;
        final phase = t * 2 * math.pi;

        // rotated ~170° to match your desired reading order around the blob
        final startAngle = 0.55 + (math.pi * (160.0 / 180.0));
        final step = (2 * math.pi) / n;

        return Stack(
          children: List.generate(n, (i) {
            final ch = letters[i];

            final baseA = startAngle + step * i;

            final a = baseA + math.sin(phase * 0.85 + i * 0.9) * 0.055;

            final r =
                rBase * (0.95 + 0.04 * math.sin(phase * 0.95 + i * 1.15));

            final dx = math.cos(phase * 1.10 + i * 1.35) * 2.4;
            final dy = math.sin(phase * 1.02 + i * 1.25) * 3.2;

            final pos = Offset(
              center.dx + r * math.cos(a) + dx,
              center.dy + r * math.sin(a) + dy,
            );

            final rot = math.sin(phase + i * 0.85) * 0.05;

            final o = 0.62 + 0.12 * math.sin(phase * 0.9 + i * 0.8);

            final style = TextStyle(
              color: baseColor.withOpacity(o.clamp(0.0, 1.0)),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.9,
              fontFamily: 'MontserratAlternates',
            );

            return Positioned(
              left: pos.dx - 8,
              top: pos.dy - 10,
              child: Transform.rotate(
                angle: rot,
                child: SizedBox(
                  width: 16,
                  height: 20,
                  child: Center(child: Text(ch, style: style)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
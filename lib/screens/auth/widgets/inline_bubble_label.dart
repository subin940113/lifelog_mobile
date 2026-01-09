// lib/screens/auth/widgets/inline_bubble_label.dart
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class InlineBubbleLabel extends StatelessWidget {
  final String text;

  const InlineBubbleLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // 디자인 유지 (요청사항 반영)
    const radius = 18.0;
    const tailH = 7.0;
    const tailW = 10.0;

    final glassFill = Colors.white.withOpacity(0.18);
    final glassStroke = Colors.white.withOpacity(0.38);

    final clipper = _BubbleWithTailClipper(
      radius: radius,
      tailHeight: tailH,
      tailWidth: tailW,
    );

    return CustomPaint(
      painter: _BubbleWithTailShadowPainter(
        radius: radius,
        tailHeight: tailH,
        tailWidth: tailW,
        shadowColor: Colors.black.withOpacity(0.22),
        elevation: 10,
      ),
      child: ClipPath(
        clipper: clipper,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: CustomPaint(
            foregroundPainter: _BubbleWithTailBorderPainter(
              radius: radius,
              tailHeight: tailH,
              tailWidth: tailW,
              stroke: glassStroke,
            ),
            child: Container(
              // 말풍선 가로 폭(좌우 padding) 조절은 여기서
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8 + tailH),
              color: glassFill,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                      fontSize: 13,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleWithTailClipper extends CustomClipper<Path> {
  final double radius;
  final double tailHeight;
  final double tailWidth;

  const _BubbleWithTailClipper({
    required this.radius,
    required this.tailHeight,
    required this.tailWidth,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final fullH = size.height;
    if (w <= 0 || fullH <= 0) {
      return Path()..addRect(Rect.fromLTWH(0, 0, w, fullH));
    }

    final h = math.max(0.0, fullH - tailHeight);

    // clamp 예외 방지(이전 크래시 방지)
    final maxR = math.max(
      0.0,
      math.min(radius, math.min(w / 2 - 0.01, h / 2 - 0.01)),
    );
    final r = maxR.isFinite ? maxR : 0.0;

    final cx = w / 2;
    final halfTailW = tailWidth / 2;

    final minX = r;
    final maxX = w - r;

    final leftTailX = (cx - halfTailW).clamp(minX, maxX);
    final rightTailX = (cx + halfTailW).clamp(minX, maxX);

    final path = Path();

    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);

    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);

    path.lineTo(rightTailX, h);
    path.lineTo(cx, h + tailHeight);
    path.lineTo(leftTailX, h);

    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);

    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BubbleWithTailClipper oldClipper) {
    return oldClipper.radius != radius ||
        oldClipper.tailHeight != tailHeight ||
        oldClipper.tailWidth != tailWidth;
  }
}

class _BubbleWithTailShadowPainter extends CustomPainter {
  final double radius;
  final double tailHeight;
  final double tailWidth;
  final Color shadowColor;
  final double elevation;

  const _BubbleWithTailShadowPainter({
    required this.radius,
    required this.tailHeight,
    required this.tailWidth,
    required this.shadowColor,
    required this.elevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final path = _BubbleWithTailClipper(
      radius: radius,
      tailHeight: tailHeight,
      tailWidth: tailWidth,
    ).getClip(size);
    canvas.drawShadow(path, shadowColor, elevation, true);
  }

  @override
  bool shouldRepaint(covariant _BubbleWithTailShadowPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.tailHeight != tailHeight ||
        oldDelegate.tailWidth != tailWidth ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.elevation != elevation;
  }
}

class _BubbleWithTailBorderPainter extends CustomPainter {
  final double radius;
  final double tailHeight;
  final double tailWidth;
  final Color stroke;

  const _BubbleWithTailBorderPainter({
    required this.radius,
    required this.tailHeight,
    required this.tailWidth,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final path = _BubbleWithTailClipper(
      radius: radius,
      tailHeight: tailHeight,
      tailWidth: tailWidth,
    ).getClip(size);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleWithTailBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.tailHeight != tailHeight ||
        oldDelegate.tailWidth != tailWidth ||
        oldDelegate.stroke != stroke;
  }
}
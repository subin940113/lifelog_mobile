// lib/widgets/glass_switch.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// Flatter glass switch (keep color, kill volume)
class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  final Color color;
  final bool enabled;
  final double width;
  final double height;
  final bool blurEnabled;

  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.color,
    this.enabled = true,
    this.width = 46,
    this.height = 28,
    this.blurEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.45;

    // ✅ 색은 유지 + 살짝만 밝게(이전 유지)
    final onBase = Color.lerp(color, Colors.white, 0.10)!;
    final offBase = const Color(0xFFE3E7EC);

    final onOpacity = 0.98;
    final offOpacity = 0.98;

    // ✅ 볼륨 줄이기: 하이라이트 강도/범위 축소
    final topHi = Colors.white.withOpacity(value ? 0.035 : 0.03);
    final botHi = Colors.white.withOpacity(0.0);

    final radius = BorderRadius.circular(999);

    final track = ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base
          DecoratedBox(
            decoration: BoxDecoration(
              color: value
                  ? onBase.withOpacity(onOpacity)
                  : offBase.withOpacity(offOpacity),
            ),
          ),

          // Optional blur (keep off by default)
          if (blurEnabled)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const SizedBox.expand(),
            ),

          // ✅ 얇은 상단 sheen만 (그라데이션 길이 짧게)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topHi, botHi],
                stops: const [0.0, 0.35],
              ),
            ),
          ),

          // ✅ 그림자 거의 제거 (flat)
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.018),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final thumbSize = height - 6;
    final thumb = _GlassThumb(size: thumbSize, active: value, accent: color);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: track),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: thumb,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassThumb extends StatelessWidget {
  final double size;
  final bool active;
  final Color accent;

  const _GlassThumb({
    required this.size,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ thumb 볼륨도 줄이기: shadow/하이라이트/바닥쉐이딩 축소
    final shadowColor = Colors.black.withOpacity(0.07);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base: slightly translucent white
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                ),
              ),

              // Top highlight (much weaker)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.7),
                    radius: 1.0,
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),

              // Bottom shading (almost none)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, 0.9),
                    radius: 1.1,
                    colors: [
                      Colors.black.withOpacity(0.025),
                      Colors.black.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),

              // When ON, add faint tint reflection (reduced)
              if (active)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.2),
                      radius: 1.0,
                      colors: [
                        accent.withOpacity(0.06),
                        accent.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.85],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

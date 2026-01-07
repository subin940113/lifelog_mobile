import 'dart:ui';
import 'package:flutter/material.dart';

/// Subtle glass switch (less “metal / bulge”, more “thin glass”)
/// - No strong outline
/// - Softer highlight, reduced shadow
/// - Slight translucency + optional background blur
class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Main accent color when ON
  final Color color;

  /// Whether user interaction is enabled
  final bool enabled;

  /// Track size
  final double width;
  final double height;

  /// Optional: apply a tiny blur to the track background.
  /// If your screen already has lots of blur/glass, you can set false.
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

    // ------------------------------------------------------------
    // ✅ 핵심 변경: “유리감 유지 + 파랑만 진하게”
    //
    // - white로 너무 보내면(0.08~0.12) 파랑이 탁/연해짐
    // - lerp는 0.03~0.05가 적절
    // - 대신 opacity를 높여 “흐림”을 제거
    // ------------------------------------------------------------
    final onBase = Color.lerp(color, Colors.white, 0.02)!; // ✅ 파랑 유지
    final offBase = const Color(0xFFE3E7EC);

    final onOpacity = 0.98; // ✅ “파랑 흐림” 제거
    final offOpacity = 0.98;

    // “Glass” overlay intensity
    final topHi = Colors.white.withOpacity(value ? 0.10 : 0.08);
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

          // Optional blur (very mild)
          if (blurEnabled)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const SizedBox.expand(),
            ),

          // Thin glass highlight (top → fade)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topHi, botHi],
                stops: const [0.0, 0.8],
              ),
            ),
          ),

          // Very subtle depth (no “metal rim”)
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final thumbSize = height - 6; // padding 3 top/bot
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
                // Track
                Positioned.fill(child: track),

                // Thumb
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
    // Thumb should feel like “white glass disk”, not plastic/metal ball.
    // Keep shadow tight and light.
    final shadowColor = Colors.black.withOpacity(0.10);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 5),
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
                  color: Colors.white.withOpacity(0.92),
                ),
              ),

              // Soft top highlight (thin glass sheen)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.7),
                    radius: 1.1,
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),

              // VERY subtle bottom shading (avoid “embossed”)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, 0.9),
                    radius: 1.2,
                    colors: [
                      Colors.black.withOpacity(0.06),
                      Colors.black.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),

              // When ON, add a faint tint reflection (not a rim)
              if (active)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.2),
                      radius: 1.1,
                      colors: [
                        accent.withOpacity(0.10),
                        accent.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.8],
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

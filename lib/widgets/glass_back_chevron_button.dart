import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GlassBackChevronButton extends StatefulWidget {
  final VoidCallback onTap;

  /// base 색상(기존 iconColor 역할). 그대로 유지됩니다.
  final Color baseColor;

  /// 입체감 강도(0.0~1.0). 0.45~0.60 권장
  final double depth;

  /// 아이콘 크기
  final double iconSize;

  /// 터치 영역
  final double hitSize;

  const GlassBackChevronButton({
    super.key,
    required this.onTap,
    required this.baseColor,
    this.depth = 0.50,
    this.iconSize = 38,
    this.hitSize = 44,
  });

  @override
  State<GlassBackChevronButton> createState() => _GlassBackChevronButtonState();
}

class _GlassBackChevronButtonState extends State<GlassBackChevronButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    SchedulerBinding.instance.endOfFrame.then((_) {
      if (!mounted) return;
      if (_pressed == v) return;
      setState(() => _pressed = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.depth.clamp(0.0, 1.0);
    final s = widget.iconSize;

    // 아이콘의 base 색상은 그대로 유지 (요청 핵심)
    final base = Icon(
      Icons.chevron_left_rounded,
      color: widget.baseColor,
      size: s,
    );

    // ✅ 베이스가 연해질수록(알파 낮을수록) 그림자/하이라이트가 사라지지 않도록 보정
    final baseA = widget.baseColor.opacity; // 0.0 ~ 1.0
    final effectBoost = (0.85 / (baseA + 0.12)).clamp(1.0, 2.2);

    // Shadow: 아래로 살짝 내리고 blur
    final shadowOpacity = (0.22 * d * effectBoost).clamp(0.0, 0.38);
    final shadowBlur = 6.0 * d;
    final shadowDy = 2.6 * d;

    // Highlight: 위로 살짝 올리고 아주 약하게
    final highlightOpacity = (0.18 * d * effectBoost).clamp(0.0, 0.32);
    final highlightBlur = 2.2 * d;
    final highlightDy = -0.9 * d;

    final iconWithDepth = Stack(
      alignment: Alignment.center,
      children: [
        // shadow (아래로)
        Transform.translate(
          offset: Offset(0, shadowDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: shadowBlur,
              sigmaY: shadowBlur,
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.black.withOpacity(shadowOpacity),
              size: s,
            ),
          ),
        ),

        // base (그대로)
        base,

        // highlight (위로)
        Transform.translate(
          offset: Offset(0, highlightDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: highlightBlur,
              sigmaY: highlightBlur,
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.white.withOpacity(highlightOpacity),
              size: s,
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: widget.hitSize,
      height: widget.hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: iconWithDepth,
          ),
        ),
      ),
    );
  }
}

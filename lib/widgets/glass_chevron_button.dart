import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GlassChevronButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color accent;

  /// 입체감 강도(0.0 ~ 1.0). 0.4~0.6 권장
  final double depth;

  /// 아이콘 크기
  final double iconSize;

  const GlassChevronButton({
    super.key,
    required this.onTap,
    required this.accent,
    this.depth = 0.50,
    this.iconSize = 30,
  });

  @override
  State<GlassChevronButton> createState() => _GlassChevronButtonState();
}

class _GlassChevronButtonState extends State<GlassChevronButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    // build scope 충돌 방지
    SchedulerBinding.instance.endOfFrame.then((_) {
      if (!mounted) return;
      if (_pressed == v) return;
      setState(() => _pressed = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    final d = widget.depth.clamp(0.0, 1.0);
    final s = widget.iconSize;

    // ✅ 배경판을 만들지 않기 위해 Container/DecoratedBox를 쓰지 않습니다.
    // 아이콘만 3겹으로 쌓아 depth를 만듭니다.

    // Shadow: 아래로 살짝 내리고 blur
    final shadowOpacity = 0.20 * d; // 0.08~0.12 정도 체감
    final shadowBlur = 6.0 * d; // 2.4~3.6 정도 체감
    final shadowDy = 2.6 * d; // 1.0~1.6 정도 체감

    // Highlight: 위로 살짝 올리고 아주 약하게
    final highlightOpacity = 0.16 * d;
    final highlightBlur = 2.0 * d;
    final highlightDy = -0.8 * d;

    final baseIcon = Icon(Icons.chevron_right_rounded, color: a, size: s);

    Widget iconWithDepth = Stack(
      alignment: Alignment.center,
      children: [
        // 1) shadow
        Transform.translate(
          offset: Offset(0, shadowDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: shadowBlur,
              sigmaY: shadowBlur,
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: Colors.black.withOpacity(shadowOpacity),
              size: s,
            ),
          ),
        ),

        // 2) base
        baseIcon,

        // 3) highlight
        Transform.translate(
          offset: Offset(0, highlightDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: highlightBlur,
              sigmaY: highlightBlur,
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(highlightOpacity),
              size: s,
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: 44,
      height: 44,
      child: Align(
        alignment: Alignment.centerRight,
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
      ),
    );
  }
}

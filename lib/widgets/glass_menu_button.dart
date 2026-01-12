import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GlassMenuButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color accent;
  final IconData icon;

  /// 입체감 강도(0.0 ~ 1.0). 0.4~0.6 권장
  final double depth;

  /// 아이콘 크기
  final double iconSize;

  /// 터치 영역 크기
  final double hitSize;

  const GlassMenuButton({
    super.key,
    required this.onTap,
    required this.accent,
    required this.icon,
    this.depth = 0.50,
    this.iconSize = 28,
    this.hitSize = 44,
  });

  @override
  State<GlassMenuButton> createState() => _GlassMenuButtonState();
}

class _GlassMenuButtonState extends State<GlassMenuButton> {
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
    final a = widget.accent;
    final d = widget.depth.clamp(0.0, 1.0);
    final s = widget.iconSize;

    // Shadow
    final shadowOpacity = 0.20 * d;
    final shadowBlur = 6.0 * d;
    final shadowDy = 2.6 * d;

    // Highlight
    final highlightOpacity = 0.16 * d;
    final highlightBlur = 2.0 * d;
    final highlightDy = -0.8 * d;

    final iconWithDepth = Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(0, shadowDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: shadowBlur,
              sigmaY: shadowBlur,
            ),
            child: Icon(
              widget.icon,
              color: Colors.black.withOpacity(shadowOpacity),
              size: s,
            ),
          ),
        ),
        Icon(widget.icon, color: a, size: s),
        Transform.translate(
          offset: Offset(0, highlightDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: highlightBlur,
              sigmaY: highlightBlur,
            ),
            child: Icon(
              widget.icon,
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

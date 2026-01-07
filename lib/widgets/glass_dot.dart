import 'package:flutter/material.dart';

/// 작은 점(Dot)을 glass 톤으로 표현.
/// - blur X
/// - 작은 컴포넌트라 shadow는 아주 약하게만
class GlassDot extends StatefulWidget {
  final double size;
  final Color color;
  final bool active;

  const GlassDot({
    super.key,
    required this.size,
    required this.color,
    required this.active,
  });

  @override
  State<GlassDot> createState() => _GlassDotState();
}

class _GlassDotState extends State<GlassDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GlassDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _c.repeat(reverse: true);
      } else {
        _c.stop();
        _c.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final c = widget.color;

    Widget dot = SizedBox(
      width: s,
      height: s,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 미세 halo
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: c.withOpacity(0.18),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),

          // base
          DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: c),
          ),

          // highlight
          ClipOval(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.85, -0.85),
                  radius: 1.15,
                  colors: [
                    Colors.white.withOpacity(0.16),
                    Colors.white.withOpacity(0.00),
                  ],
                  stops: const [0.0, 0.78],
                ),
              ),
            ),
          ),

          // rim
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
                width: 1,
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.active) return dot;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.scale(scale: _scale.value, child: dot),
    );
  }
}

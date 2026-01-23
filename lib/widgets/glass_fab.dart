import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GlassFab extends StatefulWidget {
  final VoidCallback onPressed;
  final bool enabled;
  final Color color;

  final IconData icon;
  final double size;
  final double iconSize;

  /// Optional custom icon widget (e.g. SVG/CustomPaint).
  /// If provided, `icon` is ignored.
  final Widget? iconWidget;

  /// accent → white 보정 (0.00 = accent 그대로, 0.06~0.10 권장)
  final double lighten;

  /// 눌림 scale (0.98 권장)
  final double pressedScale;

  /// 은은한 부유 효과
  final bool floatEnabled;

  const GlassFab({
    super.key,
    required this.onPressed,
    required this.color,
    this.enabled = true,
    this.icon = Icons.edit_rounded,
    this.size = 72,
    this.iconSize = 28,
    this.iconWidget,
    this.lighten = 0.06,
    this.pressedScale = 0.98,
    this.floatEnabled = true,
  });

  @override
  State<GlassFab> createState() => _GlassFabState();
}

class _GlassFabState extends State<GlassFab>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _floatC;
  late final Animation<double> _floatY;

  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _floatC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _floatY = Tween<double>(
      begin: 0.0,
      end: -2.0,
    ).animate(CurvedAnimation(parent: _floatC, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleSyncFloat();
  }

  @override
  void didUpdateWidget(covariant GlassFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.floatEnabled != widget.floatEnabled) {
      _scheduleSyncFloat();
    }
  }

  void _scheduleSyncFloat() {
    if (_syncScheduled) return;
    _syncScheduled = true;

    SchedulerBinding.instance.endOfFrame.then((_) {
      _syncScheduled = false;
      if (!mounted) return;

      final allowTickers = TickerMode.of(context);
      final shouldFloat = widget.enabled && widget.floatEnabled && allowTickers;

      if (shouldFloat) {
        if (!_floatC.isAnimating) _floatC.repeat(reverse: true);
      } else {
        if (_floatC.isAnimating) _floatC.stop();
        _floatC.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _floatC.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (!widget.enabled) return;
    if (_pressed == v) return;
    if (!mounted) return;

    SchedulerBinding.instance.endOfFrame.then((_) {
      if (!mounted) return;
      if (_pressed == v) return;
      setState(() => _pressed = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.32;

    // ✅ 다크모드에서 "배경색"만 조금 더 진하게 (텍스트 색은 건드리지 않음)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 다크모드에서 너무 밝아지는 문제는:
    // - color 자체가 밝고
    // - lighten으로 더 하얘지는 것
    // 이 두 가지가 합쳐져 생김
    //
    // 해결:
    // 1) 다크모드에선 color를 약간 더 딥한 블루로 당김
    // 2) 다크모드에선 lighten 강도를 낮춤
    final adjustedColor = isDark
        // widget.color를 살짝 "딥 블루"로 끌어당김 (너무 네이비로 가면 튀어서 중간값)
        ? Color.lerp(widget.color, const Color(0xFF2F7CC6), 0.40)!
        : widget.color;

    final adjustedLighten = isDark ? 0.02 : widget.lighten;

    final base = Color.lerp(adjustedColor, Colors.white, adjustedLighten)!;

    // ✅ GestureDetector 대신 InkWell 사용 (탭 안정성↑)
    final body = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: widget.enabled ? widget.onPressed : null,
        onHighlightChanged: (v) => _setPressed(v),
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: _GlassFabBody(
            size: widget.size,
            baseColor: base,
            accent: adjustedColor, // ✅ 그림자/광도도 조정된 컬러 기준
            icon: widget.icon,
            iconColor: Colors.white.withOpacity(0.95),
            iconSize: widget.iconSize,
            iconWidget: widget.iconWidget,
            pressed: _pressed,
          ),
        ),
      ),
    );

    final allowTickers = TickerMode.of(context);
    final shouldAnimate = widget.enabled && widget.floatEnabled && allowTickers;

    Widget result = body;
    if (shouldAnimate) {
      result = AnimatedBuilder(
        animation: _floatC,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, _floatY.value), child: child),
        child: body,
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      opacity: opacity,
      child: IgnorePointer(ignoring: !widget.enabled, child: result),
    );
  }
}

class _GlassFabBody extends StatelessWidget {
  final double size;
  final Color baseColor;
  final Color accent;
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final Widget? iconWidget;
  final bool pressed;

  const _GlassFabBody({
    required this.size,
    required this.baseColor,
    required this.accent,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.iconWidget,
    required this.pressed,
  });

  @override
  Widget build(BuildContext context) {
    final highlightBoost = pressed ? 0.04 : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.10),
                      blurRadius: 26,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: accent.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: baseColor,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.75, -0.8),
                          radius: 1.1,
                          colors: [
                            Colors.white.withOpacity(0.12 + highlightBoost),
                            Colors.white.withOpacity(0.00),
                          ],
                          stops: const [0.0, 0.72],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0.9, 0.9),
                          radius: 1.15,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.00),
                          ],
                          stops: const [0.0, 0.78],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(child: _GlassRim(baseColor: baseColor)),
                  Center(
                    child: iconWidget ??
                        Icon(icon, color: iconColor, size: iconSize),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassRim extends StatelessWidget {
  final Color baseColor;
  const _GlassRim({required this.baseColor});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GlassRimPainter(baseColor));
}

class _GlassRimPainter extends CustomPainter {
  final Color base;
  _GlassRimPainter(this.base);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;

    final rimLight = Color.lerp(base, Colors.white, 0.22)!.withOpacity(0.55);
    final rimMid = Color.lerp(base, Colors.white, 0.14)!.withOpacity(0.34);
    final rimDark = Color.lerp(base, Colors.black, 0.10)!.withOpacity(0.20);

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: -0.9,
        endAngle: 5.4,
        colors: [rimLight, rimMid, rimDark, rimMid, rimLight],
        stops: const [0.0, 0.28, 0.55, 0.78, 1.0],
      ).createShader(rect);

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: -0.9,
        endAngle: 5.4,
        colors: [
          rimMid.withOpacity(0.28),
          rimMid.withOpacity(0.16),
          rimDark.withOpacity(0.14),
          rimMid.withOpacity(0.16),
          rimMid.withOpacity(0.28),
        ],
        stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
      ).createShader(rect);

    final gluePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true
      ..color = base.withOpacity(0.16);

    final rOuter = (size.shortestSide / 2) - 0.5;
    final rInner = rOuter - 2.0;

    canvas.drawCircle(center, rOuter, outerPaint);
    canvas.drawCircle(center, rInner, innerPaint);
    canvas.drawCircle(center, rOuter - 1.0, gluePaint);
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter oldDelegate) =>
      oldDelegate.base != base;
}

class FabPosition extends StatelessWidget {
  final Widget child;
  const FabPosition({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Keep bottom lift but anchor to bottom-right.
      minimum: const EdgeInsets.only(right: 16, bottom: 0),
      child: Transform.translate(
        offset: const Offset(0, -70),
        child: Align(
          alignment: Alignment.bottomRight,
          child: child,
        ),
      ),
    );
  }
}
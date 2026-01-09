// lib/screens/record/record_widgets.dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/glass_fab.dart';

/// Minimal, text-only segmented pill for mode switching.
class ModePill extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;
  final Palette p;
  final double height;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final bool showUnderline;

  const ModePill({
    super.key,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
    required this.p,
    this.height = 40,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.showUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = !enabled ? p.muted : (active ? p.accent : p.ink);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: borderRadius,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            if (showUnderline && active)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 2,
                  width: 28,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: p.accent.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hold-to-talk pill: starts listening after a very short intent delay.
class HoldToTalkPill extends StatefulWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback onTapHint;
  final Palette p;
  final double height;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final bool showUnderline;

  const HoldToTalkPill({
    super.key,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onTapHint,
    required this.p,
    this.height = 40,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.showUnderline = false,
  });

  @override
  State<HoldToTalkPill> createState() => _HoldToTalkPillState();
}

class _HoldToTalkPillState extends State<HoldToTalkPill> {
  Timer? _holdTimer;
  bool _pressed = false;
  bool _started = false;

  static const _intentDelay = Duration(milliseconds: 50);

  void _onDown(PointerDownEvent _) {
    if (!widget.enabled) return;

    _pressed = true;
    _started = false;

    _holdTimer?.cancel();
    _holdTimer = Timer(_intentDelay, () {
      if (!mounted) return;
      if (_pressed) {
        _started = true;
        widget.onHoldStart();
      }
    });
  }

  void _finishPress({required bool canceled}) {
    if (!widget.enabled) return;

    _holdTimer?.cancel();
    _holdTimer = null;

    final started = _started;
    _pressed = false;
    _started = false;

    if (started) {
      widget.onHoldEnd();
      return;
    }

    if (!canceled) widget.onTapHint();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = !widget.enabled
        ? widget.p.muted
        : (widget.active ? widget.p.accent : widget.p.ink);

    return Listener(
      onPointerDown: _onDown,
      onPointerUp: (_) => _finishPress(canceled: false),
      onPointerCancel: (_) => _finishPress(canceled: true),
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.label,
        child: Container(
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: widget.borderRadius,
          ),
          alignment: Alignment.center,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              if (widget.showUnderline && widget.active)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 2,
                    width: 28,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: widget.p.accent.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(99),
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

class RecordingDot extends StatelessWidget {
  final Color color;
  const RecordingDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.55, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, t, child) {
        final opacity = 0.35 + (t * 0.35);
        final scale = 0.92 + (t * 0.06);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      onEnd: () {},
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class DoneFab extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final Palette p;

  final bool floatEnabled;

  const DoneFab({
    super.key,
    required this.enabled,
    required this.onPressed,
    required this.p,
    this.floatEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 24),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: GlassFab(
          onPressed: onPressed,
          enabled: enabled,
          color: p.accent,

          // ✅ check soft 적용: icon 대신 iconWidget 사용
          iconWidget: SoftCheckIcon(
            size: 30,
            color: Colors.white.withOpacity(enabled ? 1.0 : 0.55),
            stroke: 4.6,
            rotate: -0.1,
          ),

          size: 72,

          // iconSize / icon 은 iconWidget 쓰면 무시되므로 제거해도 됨
          // icon: Icons.check_rounded,
          // iconSize: 32,
          lighten: 0.06,
          pressedScale: 0.98,
          floatEnabled: floatEnabled,
        ),
      ),
    );
  }
}

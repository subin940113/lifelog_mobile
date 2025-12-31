import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lifelog_mobile/theme/palette.dart';

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
                  fontSize: 16,
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
                    fontSize: 16,
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

/// Minimal circular done button (FAB-like), centered at bottom.
class DoneFab extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final Palette p;

  const DoneFab({
    super.key,
    required this.enabled,
    required this.onPressed,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFFFFFFFF);

    // Lighter “link-like” blue (closer to the reference website tone)
    final enabledBg = Color.lerp(p.accent, Colors.white, 0.18)!;
    final disabledBg = enabledBg.withOpacity(0.38);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 24),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          opacity: enabled ? 1.0 : 0.32,
          child: IgnorePointer(
            ignoring: !enabled,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkResponse(
                onTap: onPressed,
                radius: 40,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: enabled ? enabledBg : disabledBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '✓',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

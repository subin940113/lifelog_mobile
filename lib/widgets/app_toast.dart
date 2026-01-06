import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// App-wide ultra-minimal toast (text only).
/// - One toast at a time (global)
/// - Uses palette muted color (or light fg in dark mode)
class AppToast {
  static Timer? _timer;
  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    double? bottomPadding,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final theme = Theme.of(context);
    final palette = Palette.from(theme.colorScheme);
    final isDark = theme.brightness == Brightness.dark;

    // Ultra-minimal: text only
    final fg = isDark ? const Color(0xFFECECEC) : palette.muted;

    // clear previous
    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final media = MediaQuery.of(context);
    final effectiveBottomPadding = bottomPadding ?? (media.padding.bottom + 18);

    final entry = OverlayEntry(
      builder: (_) {
        return IgnorePointer(
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: effectiveBottomPadding),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  builder: (context, t, child) => Opacity(opacity: t, child: child),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () {
      _entry?.remove();
      _entry = null;
    });
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}
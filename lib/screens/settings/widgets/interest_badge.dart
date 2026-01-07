// lib/screens/settings/insight/widgets/interest_badge.dart
import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// Matches GlassSwitch track vibe (thin glass, flatter)
/// - Very low depth (almost flat)
/// - Crisp text
class InterestBadge extends StatelessWidget {
  final Palette p;
  final String text;
  final VoidCallback? onRemove;

  /// if false, render as subtle off badge (still visible)
  final bool active;

  const InterestBadge({
    super.key,
    required this.p,
    required this.text,
    this.onRemove,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(999);

    // ✅ Same recipe as GlassSwitch (keep blue vivid)
    final onBase = Color.lerp(p.accent, Colors.white, 0.02)!;
    final offBase = const Color(0xFFE3E7EC);

    final bg = (active ? onBase : offBase).withOpacity(0.98);

    // ✅ Same thin highlight as GlassSwitch track
    final topHi = Colors.white.withOpacity(active ? 0.10 : 0.08);
    final botHi = Colors.white.withOpacity(0.0);

    // ✅ Make it flatter:
    // - reduce blur and vertical offset drastically
    // - keep opacity low to avoid “floating pill”
    final shadow = BoxShadow(
      color: Colors.black.withOpacity(0.035),
      blurRadius: 3,
      offset: const Offset(0, 1),
    );

    final badge = ClipRRect(
      borderRadius: r,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: r,
          boxShadow: [shadow],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [topHi, botHi],
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  // ✅ crisper
                  color: active
                      ? Colors.white.withOpacity(0.98)
                      : p.ink.withOpacity(0.78),
                  // ✅ weight down one step, but keep clarity via opacity
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onRemove == null) return badge;

    return InkWell(
      onLongPress: onRemove,
      borderRadius: r,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: badge,
    );
  }
}

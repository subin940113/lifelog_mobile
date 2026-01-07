// lib/screens/settings/insight/widgets/interest_badge.dart
import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// Flatter badge (keep color, kill gradient volume)
class InterestBadge extends StatelessWidget {
  final Palette p;
  final String text;
  final VoidCallback? onRemove;
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

    // ✅ 색은 유지 + 살짝만 밝게
    final onBase = Color.lerp(p.accent, Colors.white, 0.10)!;
    final offBase = const Color(0xFFE3E7EC);
    final bg = (active ? onBase : offBase).withOpacity(0.98);

    // ✅ 볼륨 줄이기: 하이라이트 강도/범위 축소
    final topHi = Colors.white.withOpacity(active ? 0.035 : 0.03);
    final botHi = Colors.white.withOpacity(0.0);

    // ✅ 그림자 거의 제거
    final shadow = BoxShadow(
      color: Colors.black.withOpacity(0.016),
      blurRadius: 2,
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
                    // ✅ 위쪽만 살짝
                    stops: const [0.0, 0.35],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: active
                      ? Colors.white.withOpacity(0.98)
                      : p.ink.withOpacity(0.78),
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  letterSpacing: -0.1,
                  fontSize: 16,
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

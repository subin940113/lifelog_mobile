import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// Flat badge + X(remove)
/// - 배지 전체 탭은 아무 동작 없음
/// - 삭제는 X 버튼만
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

    final onBase = Color.lerp(p.accent, Colors.white, 0.10)!;
    final offBase = const Color(0xFFE3E7EC);
    final bg = (active ? onBase : offBase).withOpacity(0.98);

    final topHi = Colors.white.withOpacity(active ? 0.035 : 0.03);
    final botHi = Colors.white.withOpacity(0.0);

    final shadow = BoxShadow(
      color: Colors.black.withOpacity(0.016),
      blurRadius: 2,
      offset: const Offset(0, 1),
    );

    final fg = active
        ? Colors.white.withOpacity(0.98)
        : p.ink.withOpacity(0.78);

    return ClipRRect(
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
                    stops: const [0.0, 0.35],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: -0.1,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (onRemove != null) ...[
                    const SizedBox(width: 2),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onRemove,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: fg.withOpacity(0.92),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

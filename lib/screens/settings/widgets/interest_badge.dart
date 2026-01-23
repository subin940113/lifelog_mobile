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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ GlassFab과 동일한 원리: 다크모드에서 배경(베이스)만 과하게 밝아지지 않도록
    // 1) accent를 약간 더 딥한 톤으로 끌어당기고
    // 2) white로 보정(lighten) 강도를 낮춘다.
    final adjustedAccent = isDark
        ? Color.lerp(p.accent, const Color(0xFF2F7CC6), 0.40)!
        : p.accent;

    final adjustedLighten = isDark ? 0.02 : 0.10;

    // Active 배경: 라이트는 기존처럼 산뜻하게, 다크는 과하게 밝아지지 않도록 조정
    final onBase = Color.lerp(adjustedAccent, Colors.white, adjustedLighten)!;

    // Inactive 배경도 다크모드에선 약간 더 눌러준다.
    final offBase = isDark ? const Color(0xFF2A2E35) : const Color(0xFFE3E7EC);

    final bg = (active ? onBase : offBase).withOpacity(isDark ? 0.96 : 0.98);

    // 하이라이트도 다크모드에서는 더 약하게
    final topHi = Colors.white.withOpacity(
      active ? (isDark ? 0.020 : 0.035) : (isDark ? 0.016 : 0.03),
    );
    final botHi = Colors.white.withOpacity(0.0);

    final shadow = BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.06 : 0.016),
      blurRadius: isDark ? 6 : 2,
      offset: const Offset(0, 1),
    );

    // 텍스트/아이콘 컬러: active는 화이트를 유지하되 다크에서는 눈부심을 살짝 완화
    final fg = active
        ? (isDark
              ? Colors.white.withOpacity(0.92)
              : Colors.white.withOpacity(0.98))
        : p.ink.withOpacity(isDark ? 0.72 : 0.78);

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
                        child: Icon(Icons.close_rounded, size: 16, color: fg),
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

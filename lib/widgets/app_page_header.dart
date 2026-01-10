import 'package:flutter/material.dart';

/// SettingsPageHeader와 별개로 쓰는 공통 헤더(좌측 정렬, < + 타이틀)
/// + 모든 플랫폼에서 "왼쪽 edge에서 우측 스와이프"로 뒤로가기 지원(헤더 영역 내)
class AppPageHeader extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final Color? iconColor;

  /// 스와이프 시작을 허용할 왼쪽 edge 폭(px)
  final double backSwipeEdgeWidth;

  /// 뒤로가기 트리거 이동 거리(px)
  final double backSwipeTriggerDistance;

  /// 뒤로가기 트리거 속도(px/s)
  final double backSwipeTriggerVelocity;

  /// 스와이프 뒤로가기 활성화 여부
  final bool enableBackSwipe;

  const AppPageHeader({
    super.key,
    required this.title,
    this.titleColor,
    this.iconColor,
    this.backSwipeEdgeWidth = 24,
    this.backSwipeTriggerDistance = 80,
    this.backSwipeTriggerVelocity = 900,
    this.enableBackSwipe = true,
  });

  @override
  Widget build(BuildContext context) {
    // swipe state (Stateless에서 처리하기 위해 closure 변수 사용)
    double dx = 0;
    bool tracking = false;

    void reset() {
      dx = 0;
      tracking = false;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: enableBackSwipe
          ? (details) {
              final startX = details.localPosition.dx;
              tracking = startX <= backSwipeEdgeWidth; // 왼쪽 edge에서 시작해야만
              dx = 0;
            }
          : null,
      onHorizontalDragUpdate: enableBackSwipe
          ? (details) {
              if (!tracking) return;
              // 오른쪽(+) 방향만 누적
              final delta = details.delta.dx;
              if (delta > 0) dx += delta;
            }
          : null,
      onHorizontalDragEnd: enableBackSwipe
          ? (details) {
              if (!tracking) return;

              final velocityX = details.primaryVelocity ?? 0; // +면 오른쪽
              final shouldPop =
                  (dx >= backSwipeTriggerDistance) || (velocityX >= backSwipeTriggerVelocity);

              reset();

              if (shouldPop) {
                Navigator.of(context).maybePop();
              }
            }
          : null,
      onHorizontalDragCancel: enableBackSwipe ? reset : null,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 35),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                        ),
                  ),
                ),
              ),
              Positioned(
                left: -5,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: iconColor?.withOpacity(0.7),
                      size: 38,
                    ),
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
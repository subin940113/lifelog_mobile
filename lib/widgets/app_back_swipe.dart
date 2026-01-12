import 'package:flutter/material.dart';

/// 화면 어디서든 "왼쪽 edge에서 우측 스와이프"로 뒤로가기.
/// - iOS/Android/데스크톱 전부 동일 동작
/// - 수평 스크롤/슬라이더/캐러셀과 충돌을 줄이기 위해 "왼쪽 edge에서 시작"만 허용
class AppBackSwipe extends StatefulWidget {
  final Widget child;

  /// 스와이프 시작을 허용할 왼쪽 edge 폭(px)
  final double edgeWidth;

  /// 뒤로가기 트리거 이동 거리(px)
  final double triggerDistance;

  /// 뒤로가기 트리거 속도(px/s)
  final double triggerVelocity;

  /// 뒤로가기 활성화 여부
  final bool enabled;

  /// 뒤로가기 가능 여부(예: 특정 페이지에서 막기)
  final bool canPop;

  const AppBackSwipe({
    super.key,
    required this.child,
    this.edgeWidth = 24,
    this.triggerDistance = 90,
    this.triggerVelocity = 900,
    this.enabled = true,
    this.canPop = true,
  });

  @override
  State<AppBackSwipe> createState() => _AppBackSwipeState();
}

class _AppBackSwipeState extends State<AppBackSwipe> {
  double _dx = 0;
  bool _tracking = false;

  void _reset() {
    _dx = 0;
    _tracking = false;
  }

  bool get _isEnabled => widget.enabled && widget.canPop;

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        // 왼쪽 edge에서 시작한 스와이프만 뒤로가기로 인정
        final startX = details.localPosition.dx;
        _tracking = startX <= widget.edgeWidth;
        _dx = 0;
      },
      onHorizontalDragUpdate: (details) {
        if (!_tracking) return;
        final delta = details.delta.dx;
        // 오른쪽(+) 방향만 누적
        if (delta > 0) _dx += delta;
      },
      onHorizontalDragCancel: _reset,
      onHorizontalDragEnd: (details) {
        if (!_tracking) return;

        final velocityX = details.primaryVelocity ?? 0; // +면 오른쪽
        final shouldPop =
            (_dx >= widget.triggerDistance) ||
            (velocityX >= widget.triggerVelocity);

        _reset();

        if (!shouldPop) return;

        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.maybePop();
        }
      },
      child: widget.child,
    );
  }
}

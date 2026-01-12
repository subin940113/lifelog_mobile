import 'package:flutter/material.dart';
import 'package:lifelog_mobile/widgets/app_back_swipe.dart';

class AppSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  /// 앱 공통 좌우 패딩
  final double horizontal;

  /// 전역 스와이프 뒤로가기 활성화
  final bool backSwipeEnabled;

  /// 스와이프 시작을 허용할 왼쪽 edge 폭(px)
  final double backSwipeEdgeWidth;

  /// 뒤로가기 트리거 이동 거리(px)
  final double backSwipeTriggerDistance;

  /// 뒤로가기 트리거 속도(px/s)
  final double backSwipeTriggerVelocity;

  const AppSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.horizontal = 10,
    this.backSwipeEnabled = true,
    this.backSwipeEdgeWidth = 24,
    this.backSwipeTriggerDistance = 90,
    this.backSwipeTriggerVelocity = 900,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: child,
      ),
    );

    // AppSafeArea를 쓰는 모든 화면에서 "왼쪽 edge 스와이프 뒤로가기" 활성화
    return AppBackSwipe(
      enabled: backSwipeEnabled,
      edgeWidth: backSwipeEdgeWidth,
      triggerDistance: backSwipeTriggerDistance,
      triggerVelocity: backSwipeTriggerVelocity,
      child: content,
    );
  }
}

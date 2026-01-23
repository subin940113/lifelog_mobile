import 'dart:ui';
import 'package:flutter/material.dart';
import 'glass_back_chevron_button.dart';

/// 좌측 리딩 아이콘 타입
enum AppPageHeaderLeading {
  back, // <
  close, // X
}

/// SettingsPageHeader와 별개로 쓰는 공통 헤더
/// - 좌측 정렬
/// - < 또는 X 아이콘
/// - 헤더 영역에서 "왼쪽 edge → 우측 스와이프" 뒤로가기 지원
class AppPageHeader extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final Color? iconColor;

  /// 리딩 아이콘 타입 (< / X)
  final AppPageHeaderLeading leading;

  /// 스와이프 시작을 허용할 왼쪽 edge 폭(px)
  final double backSwipeEdgeWidth;

  /// 뒤로가기 트리거 이동 거리(px)
  final double backSwipeTriggerDistance;

  /// 뒤로가기 트리거 속도(px/s)
  final double backSwipeTriggerVelocity;

  /// 스와이프 뒤로가기 활성화 여부
  final bool enableBackSwipe;

  /// 리딩 아이콘 표시 여부
  final bool showLeading;

  const AppPageHeader({
    super.key,
    required this.title,
    this.titleColor,
    this.iconColor,
    this.leading = AppPageHeaderLeading.back,
    this.backSwipeEdgeWidth = 24,
    this.backSwipeTriggerDistance = 80,
    this.backSwipeTriggerVelocity = 900,
    this.enableBackSwipe = true,
    this.showLeading = true,
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

    final baseIconColor =
        (iconColor ?? Theme.of(context).iconTheme.color ?? Colors.black)
            .withOpacity(0.52);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: enableBackSwipe
          ? (details) {
              final startX = details.localPosition.dx;
              tracking = startX <= backSwipeEdgeWidth;
              dx = 0;
            }
          : null,
      onHorizontalDragUpdate: enableBackSwipe
          ? (details) {
              if (!tracking) return;
              final delta = details.delta.dx;
              if (delta > 0) dx += delta;
            }
          : null,
      onHorizontalDragEnd: enableBackSwipe
          ? (details) {
              if (!tracking) return;

              final velocityX = details.primaryVelocity ?? 0;
              final shouldPop =
                  (dx >= backSwipeTriggerDistance) ||
                  (velocityX >= backSwipeTriggerVelocity);

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
              /// Title
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: showLeading ? 35 : 0),
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

              /// Leading icon (< or X)
              if (showLeading)
                Positioned(
                  left: -5,
                  child: leading == AppPageHeaderLeading.back
                      ? GlassBackChevronButton(
                          onTap: () => Navigator.of(context).maybePop(),
                          baseColor: baseIconColor,
                          depth: 0.55,
                          iconSize: 38,
                          hitSize: 44,
                        )
                      : _GlassCloseButton(
                          color: baseIconColor,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 내부 전용: Glass 느낌의 X 버튼
class _GlassCloseButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;

  const _GlassCloseButton({required this.color, required this.onTap});

  @override
  State<_GlassCloseButton> createState() => _GlassCloseButtonState();
}

class _GlassCloseButtonState extends State<_GlassCloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const double depth = 0.52;
    const double iconSize = 34;

    // Softer glass values
    final shadowOpacity = 0.16 * depth;
    final shadowBlur = 5.0 * depth;
    final shadowDy = 2.2 * depth;

    final highlightOpacity = 0.12 * depth;
    final highlightBlur = 1.6 * depth;
    final highlightDy = -0.6 * depth;

    final icon = Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(0, shadowDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: shadowBlur,
              sigmaY: shadowBlur,
            ),
            child: Icon(
              Icons.clear_rounded,
              color: Colors.black.withOpacity(shadowOpacity),
              size: iconSize,
            ),
          ),
        ),
        Icon(Icons.clear_rounded, color: widget.color, size: iconSize),
        Transform.translate(
          offset: Offset(0, highlightDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: highlightBlur,
              sigmaY: highlightBlur,
            ),
            child: Icon(
              Icons.clear_rounded,
              color: Colors.white.withOpacity(highlightOpacity),
              size: iconSize,
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: 44,
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: icon,
          ),
        ),
      ),
    );
  }
}

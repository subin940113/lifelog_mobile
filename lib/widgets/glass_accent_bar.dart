import 'package:flutter/material.dart';

/// Muted glass-like accent bar
/// - 거의 평면에 가까움
/// - 강한 하이라이트 / 블러 / 메탈감 제거
/// - 컬러 깊이만 살짝 있는 “감각적인 스트립”
class GlassAccentBar extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const GlassAccentBar({
    super.key,
    required this.color,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // 🎯 핵심: white로 거의 섞지 않는다
    // → 색을 “유리처럼 연하게” 만들지 않음
    final base = Color.lerp(color, Colors.black, 0.04)!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: base.withOpacity(0.95),

        // 아주 미세한 톤 차이만
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base.withOpacity(0.98), base.withOpacity(0.92)],
        ),
      ),
    );
  }
}

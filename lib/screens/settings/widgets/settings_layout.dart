import 'package:flutter/material.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/app_page_header.dart';
import 'package:lifelog_mobile/widgets/app_safe_area.dart';

class SettingsLayout extends StatelessWidget {
  final Palette p;
  final String title;
  final Widget child;

  /// AppSafeArea 기본 좌우 패딩(유지)
  final double safeHorizontal;

  /// 타이틀 좌우 기준선(최종 값)
  /// - "<" 아이콘과 맞추고 싶으면 10(= safeHorizontal) 권장
  final double titleHorizontal;

  /// 본문(리스트) 좌우 기준선(최종 값)
  /// - 기존 ListView padding(18) 유지 권장
  final double contentHorizontal;

  final double topSpacing;
  final double titleBottomSpacing;

  const SettingsLayout({
    super.key,
    required this.p,
    required this.title,
    required this.child,
    this.safeHorizontal = 10,
    this.titleHorizontal = 10,
    this.contentHorizontal = 18,
    this.topSpacing = 20,
    this.titleBottomSpacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    // AppSafeArea(10) 위에 "추가로" 더할 값만 계산
    final titleExtra = (titleHorizontal - safeHorizontal).clamp(0.0, 999.0);
    final contentExtra = (contentHorizontal - safeHorizontal).clamp(0.0, 999.0);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: AppPageHeader(title: '', titleColor: p.ink, iconColor: p.ink),
      ),
      body: AppSafeArea(
        top: false,
        horizontal: safeHorizontal, // ✅ AppSafeArea 패딩 유지
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topSpacing),

            // ✅ 타이틀은 < 아이콘 기준선에 맞춤 (보통 10)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: titleExtra),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            SizedBox(height: titleBottomSpacing),

            // ✅ 본문은 기존 리스트 기준선(18) 유지
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: contentExtra),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

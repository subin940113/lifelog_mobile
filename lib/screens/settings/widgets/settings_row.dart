import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

class SettingsRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Palette p;

  /// 완전 커스텀 trailing (예: Switch 등)
  final Widget? trailing;

  /// trailing 텍스트 (예: 현재 테마명)
  final String? trailingText;

  /// > 표시 여부
  final bool showChevron;

  /// 우측 요소들 간격
  final double rightGap;

  /// chevron 크기
  final double chevronSize;

  /// trailingText 크기
  final double trailingTextSize;

  const SettingsRow({
    super.key,
    required this.title,
    required this.onTap,
    required this.p,
    this.trailing,
    this.trailingText,
    this.showChevron = true,
    this.rightGap = 6,
    this.chevronSize = 26,
    this.trailingTextSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> rightItems = [];

    // custom trailing
    if (trailing != null) rightItems.add(trailing!);

    // trailing text
    if (trailingText != null) {
      rightItems.add(
        Text(
          trailingText!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: showChevron? p.accent : p.muted,
            fontWeight: FontWeight.w500,
            fontSize: trailingTextSize,
          ),
        ),
      );
    }

    // chevron
    if (showChevron) {
      rightItems.add(
        Icon(Icons.chevron_right_rounded, color: p.muted, size: chevronSize),
      );
    }

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ),

            // ✅ trailing + text + chevron 나란히
            if (rightItems.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _withGaps(rightItems, gap: rightGap),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> items, {required double gap}) {
    if (items.length <= 1) return items;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(SizedBox(width: gap));
      out.add(items[i]);
    }
    return out;
  }
}

import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

// ✅ glass accent bar
import 'package:lifelog_mobile/widgets/glass_accent_bar.dart';

class AccountHeader extends StatelessWidget {
  final Palette p;
  final String accountName;

  const AccountHeader({super.key, required this.p, required this.accountName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? p.bg : Colors.white;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 18, 16),
          child: Row(
            children: [
              // 좌측 아이콘/플레이스홀더 영역 (선택적으로 활용 가능)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.ink.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: p.ink.withOpacity(0.9),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: p.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '개인 설정 · 계정 관리',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Divider(
          height: 1,
          thickness: 1,
          color: p.ink.withOpacity(isDark ? 0.12 : 0.08),
        ),
      ],
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: p.muted.withOpacity(0.12), width: 1),
        ),
      ),
      child: Row(
        children: [
          // 🔵 기존 accent bar → glass bar (사이즈 동일)
          GlassAccentBar(
            color: p.accent,
            width: 4,
            height: 44,
            borderRadius: BorderRadius.circular(2),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ 기존 텍스트 그대로 유지
                Text(
                  accountName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: p.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '계정',
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
    );
  }
}

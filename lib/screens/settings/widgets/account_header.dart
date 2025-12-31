import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

class AccountHeader extends StatelessWidget {
  final Palette p;
  final String accountName;
  const AccountHeader({
    super.key,
    required this.p,
    required this.accountName,
  });

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
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(2),
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

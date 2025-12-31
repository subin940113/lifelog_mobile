import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

class AccountHeader extends StatelessWidget {
  final Palette p;
  const AccountHeader({super.key, required this.p});

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.muted.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline_rounded, color: p.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '계정',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '로그인/계정 생성 기능을 추후 추가할 예정입니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted,
                        height: 1.35,
                        fontSize: 14,
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
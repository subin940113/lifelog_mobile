import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

class SettingsRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Palette p;
  final Widget? trailing;
  final String? trailingText;
  final bool showChevron;

  const SettingsRow({
    super.key,
    required this.title,
    required this.onTap,
    required this.p,
    this.trailing,
    this.trailingText,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final right =
        trailing ??
        (trailingText != null
            ? Text(
                trailingText!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.muted,
                  fontWeight: FontWeight.w500,
                ),
              )
            : (showChevron
                  ? Icon(Icons.chevron_right_rounded, color: p.muted)
                  : const SizedBox.shrink()));

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: p.muted.withOpacity(0.12), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            right,
          ],
        ),
      ),
    );
  }
}

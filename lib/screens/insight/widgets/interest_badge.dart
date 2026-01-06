import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

class InterestBadge extends StatelessWidget {
  final Palette p;
  final String text;
  final VoidCallback? onRemove; // optional (for manage page)

  const InterestBadge({
    super.key,
    required this.p,
    required this.text,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bg = p.accent;
    const fg = Colors.white;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
      ),
    );

    if (onRemove == null) return badge;

    // Minimal UX: long-press to remove
    return InkWell(
      onLongPress: onRemove,
      borderRadius: BorderRadius.circular(999),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: badge,
    );
  }
}
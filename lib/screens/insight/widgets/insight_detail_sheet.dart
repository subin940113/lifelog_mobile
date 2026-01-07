import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

enum InsightKindUi {
  tendency,
  pattern,
  highlight,
  warning,
  reflection,
  contrast,
  question,
}

class InsightPreviewUi {
  final InsightKindUi kind;
  final String title;
  final String body;
  final String? evidence;

  const InsightPreviewUi({
    required this.kind,
    required this.title,
    required this.body,
    this.evidence,
  });

  static InsightKindUi kindFrom(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'PATTERN':
        return InsightKindUi.pattern;
      case 'HIGHLIGHT':
        return InsightKindUi.highlight;
      case 'WARNING':
        return InsightKindUi.warning;
      case 'REFLECTION':
        return InsightKindUi.reflection;
      case 'CONTRAST':
        return InsightKindUi.contrast;
      case 'QUESTION':
        return InsightKindUi.question;
      case 'TENDENCY':
      default:
        return InsightKindUi.tendency;
    }
  }

  factory InsightPreviewUi.fromJson(Map<String, dynamic> m) {
    return InsightPreviewUi(
      kind: kindFrom(m['kind'] as String?),
      title: (m['title'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      evidence: (m['evidence'] as String?),
    );
  }
}

class InsightDetailSheet extends StatelessWidget {
  final Palette p;
  final InsightPreviewUi item;

  const InsightDetailSheet({super.key, required this.p, required this.item});

  String labelFor(InsightKindUi kind) {
    switch (kind) {
      case InsightKindUi.tendency:
        return '성향';
      case InsightKindUi.pattern:
        return '패턴';
      case InsightKindUi.highlight:
        return '포인트';
      case InsightKindUi.warning:
        return '주의';
      case InsightKindUi.reflection:
        return '회고';
      case InsightKindUi.contrast:
        return '대비';
      case InsightKindUi.question:
        return '질문';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = labelFor(item.kind);
    final evidence = (item.evidence ?? '').trim();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: p.accent.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: p.muted,
                  fontWeight: FontWeight.w500,
                  height: 1.55,
                  fontSize: 16,
                ),
              ),
              if (evidence.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '참고',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: p.muted.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.muted.withOpacity(0.12)),
                  ),
                  child: Text(
                    evidence,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: p.ink.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showInsightDetailSheet(
  BuildContext context, {
  required Palette p,
  required InsightPreviewUi item,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.bg,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => InsightDetailSheet(p: p, item: item),
  );
}

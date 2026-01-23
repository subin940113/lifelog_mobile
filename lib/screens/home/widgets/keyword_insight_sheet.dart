import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

class KeywordInsightSheet extends StatelessWidget {
  final Palette p;
  final String keywordKey;
  final String? insightText;

  const KeywordInsightSheet({
    super.key,
    required this.p,
    required this.keywordKey,
    required this.insightText,
  });

  static Future<void> show({
    required BuildContext context,
    required Palette p,
    required String keywordKey,
    required String? insightText,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'keyword_insight',
      barrierColor: Colors.black.withOpacity(0.28),
      transitionDuration: const Duration(milliseconds: 190),
      pageBuilder: (ctx, a1, a2) {
        return SafeArea(
          child: Center(
            child: _ModalScaffold(
              p: p,
              child: KeywordInsightSheet(
                p: p,
                keywordKey: keywordKey,
                insightText: insightText,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = p.accent;

    // Badge tone tuned to Bluelog style (pill, subtle tint)
    final chipBg = Color.lerp(p.bg, accent, isDark ? 0.16 : 0.10)!;
    final chipFg = Color.lerp(p.ink, accent, isDark ? 0.22 : 0.18)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Keyword title
          Align(
            alignment: Alignment.centerRight,
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    keywordKey,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: p.ink,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          height: 1.12,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(isDark ? 0.78 : 0.66),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Body (scrollable with max height)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (MediaQuery.of(context).size.height * 0.55).clamp(220.0, 420.0),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                (insightText?.trim().isNotEmpty == true)
                    ? insightText!.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n')
                    : '아직 인사이트가 없어요.',
                softWrap: true,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: p.ink.withOpacity(0.88),
                      height: 1.62,
                      letterSpacing: -0.1,
                      fontSize: 16.5,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalScaffold extends StatelessWidget {
  final Palette p;
  final Widget child;

  const _ModalScaffold({
    required this.p,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width;
    final dialogW = (maxW - 32).clamp(0.0, 380.0);

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: dialogW),
        child: Container(
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

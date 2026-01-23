import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/glass_dot.dart';
import 'package:lifelog_mobile/api/insight_feedback_api_client.dart' as fb_api;

typedef InsightFeedbackSubmit =
    Future<void> Function(
      InsightFeedbackVote vote, {
      InsightFeedbackReason? reason,
      String? comment,
    });

enum InsightFeedbackVote { like, dislike }

enum InsightFeedbackReason {
  tooObvious,
  duplicate,
  tooSharp,
  notRelevant,
  badTiming,
  other,
}

enum InsightKindUi {
  tendency,
  pattern,
  highlight,
  warning,
  reflection,
  contrast,
  question,
}

// In-memory cache for last feedback per insight
class _InsightFeedbackCache {
  static final Map<int, _CachedFeedback> _byInsightId =
      <int, _CachedFeedback>{};

  static _CachedFeedback? get(int insightId) => _byInsightId[insightId];

  static void set(int insightId, _CachedFeedback v) {
    if (insightId <= 0) return;
    _byInsightId[insightId] = v;
  }
}

class _CachedFeedback {
  final InsightFeedbackVote vote;
  final InsightFeedbackReason? reason;
  final String? comment;

  const _CachedFeedback({required this.vote, this.reason, this.comment});

  bool sameAs(InsightFeedbackVote v, InsightFeedbackReason? r, String? c) {
    final cc = (c ?? '').trim();
    final mc = (comment ?? '').trim();
    return vote == v && reason == r && cc == mc;
  }
}

class InsightPreviewUi {
  final int id;
  final InsightKindUi kind;
  final String title;
  final String body;
  final String? evidence;

  const InsightPreviewUi({
    required this.id,
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
      id: (m['id'] as num?)?.toInt() ?? 0,
      kind: kindFrom(m['kind'] as String?),
      title: (m['title'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      evidence: (m['evidence'] as String?),
    );
  }
}

class InsightDetailSheet extends StatefulWidget {
  final Palette p;
  final InsightPreviewUi item;
  final InsightFeedbackSubmit? onSubmitFeedback;
  final fb_api.InsightFeedbackApiClient? feedbackApi;

  const InsightDetailSheet({
    super.key,
    required this.p,
    required this.item,
    this.onSubmitFeedback,
    this.feedbackApi,
  });

  @override
  State<InsightDetailSheet> createState() => _InsightDetailSheetState();
}

class _InsightDetailSheetState extends State<InsightDetailSheet> {
  InsightFeedbackVote? _vote;

  @override
  void initState() {
    super.initState();

    final cached = _InsightFeedbackCache.get(widget.item.id);
    if (cached != null) {
      _vote = cached.vote;
    }

    // Load existing feedback from server when opening the sheet.
    // Runs after first frame so it doesn't block sheet animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingFeedbackIfNeeded();
    });
  }

  Future<void> _loadExistingFeedbackIfNeeded() async {
    final api = widget.feedbackApi;
    final insightId = widget.item.id;
    if (api == null) return;
    if (insightId <= 0) return;

    // If we already have a cached value, keep it (user may have just voted locally).
    final cached = _InsightFeedbackCache.get(insightId);
    if (cached != null) return;

    try {
      final remote = await api.getOne(insightId: insightId);
      if (!mounted) return;
      if (remote == null) return;

      final localVote = _mapVoteFromApi(remote.vote);
      final localReason = remote.reason == null
          ? null
          : _mapReasonFromApi(remote.reason!);
      final localComment = (remote.comment ?? '').trim();

      _InsightFeedbackCache.set(
        insightId,
        _CachedFeedback(
          vote: localVote,
          reason: localReason,
          comment: localComment.isEmpty ? null : localComment,
        ),
      );

      setState(() {
        _vote = localVote;
      });
    } catch (_) {
      // silent on purpose
    }
  }

  InsightFeedbackVote _mapVoteFromApi(fb_api.InsightFeedbackVote v) {
    switch (v) {
      case fb_api.InsightFeedbackVote.like:
        return InsightFeedbackVote.like;
      case fb_api.InsightFeedbackVote.dislike:
        return InsightFeedbackVote.dislike;
    }
  }

  InsightFeedbackReason _mapReasonFromApi(fb_api.InsightFeedbackReason r) {
    switch (r) {
      case fb_api.InsightFeedbackReason.tooObvious:
        return InsightFeedbackReason.tooObvious;
      case fb_api.InsightFeedbackReason.duplicate:
        return InsightFeedbackReason.duplicate;
      case fb_api.InsightFeedbackReason.tooSharp:
        return InsightFeedbackReason.tooSharp;
      case fb_api.InsightFeedbackReason.notRelevant:
        return InsightFeedbackReason.notRelevant;
      case fb_api.InsightFeedbackReason.badTiming:
        return InsightFeedbackReason.badTiming;
      case fb_api.InsightFeedbackReason.other:
        return InsightFeedbackReason.other;
    }
  }

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

  Future<void> _submit(
    InsightFeedbackVote vote, {
    InsightFeedbackReason? reason,
    String? comment,
  }) async {
    setState(() => _vote = vote);

    final insightId = widget.item.id;
    final cached = _InsightFeedbackCache.get(insightId);
    final normalizedComment = (comment ?? '').trim();
    // If the same feedback was already recorded, do nothing (no re-submit).
    if (cached != null &&
        cached.sameAs(
          vote,
          reason,
          normalizedComment.isEmpty ? null : normalizedComment,
        )) {
      return;
    }

    // Optimistically cache so the UI reflects the selection even if the sheet is reopened.
    _InsightFeedbackCache.set(
      insightId,
      _CachedFeedback(
        vote: vote,
        reason: reason,
        comment: normalizedComment.isEmpty ? null : normalizedComment,
      ),
    );

    // Preferred: external handler (if provided)
    final cb = widget.onSubmitFeedback;
    if (cb != null) {
      try {
        await cb(vote, reason: reason, comment: comment);
      } catch (e, s) {
        // Optionally handle error (previously logged)
      }
      return;
    }

    // Fallback: submit via API client (if provided)
    final api = widget.feedbackApi;
    if (api == null) {
      return;
    }

    // If we don't have a valid insight id, do nothing.
    if (insightId <= 0) {
      return;
    }

    try {
      await api.submit(
        insightId: insightId,
        vote: vote == InsightFeedbackVote.like
            ? fb_api.InsightFeedbackVote.like
            : fb_api.InsightFeedbackVote.dislike,
        reason: reason == null ? null : _mapReason(reason),
        comment: comment,
      );
    } catch (e, s) {
      // Optionally handle error (previously logged)
    }
  }

  fb_api.InsightFeedbackReason _mapReason(InsightFeedbackReason r) {
    switch (r) {
      case InsightFeedbackReason.tooObvious:
        return fb_api.InsightFeedbackReason.tooObvious;
      case InsightFeedbackReason.duplicate:
        return fb_api.InsightFeedbackReason.duplicate;
      case InsightFeedbackReason.tooSharp:
        return fb_api.InsightFeedbackReason.tooSharp;
      case InsightFeedbackReason.notRelevant:
        return fb_api.InsightFeedbackReason.notRelevant;
      case InsightFeedbackReason.badTiming:
        return fb_api.InsightFeedbackReason.badTiming;
      case InsightFeedbackReason.other:
        return fb_api.InsightFeedbackReason.other;
    }
  }

  Future<void> _onLike() => _submit(InsightFeedbackVote.like);

  Future<void> _onDislike() async {
    final cached = _InsightFeedbackCache.get(widget.item.id);
    final res = await _showDislikeReasonSheet(
      context,
      p: widget.p,
      initialReason: cached?.vote == InsightFeedbackVote.dislike
          ? cached?.reason
          : null,
      initialComment: cached?.vote == InsightFeedbackVote.dislike
          ? cached?.comment
          : null,
    );
    if (!mounted) return;

    // User closed sheet without choosing
    if (res == null) return;

    await _submit(
      InsightFeedbackVote.dislike,
      reason: res.reason,
      comment: res.comment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final item = widget.item;

    final label = labelFor(item.kind);

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
                  GlassDot(
                    size: 8,
                    color: p.accent,
                    active: false, // 디테일 시트에서는 pulse 없음
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: p.accent.withOpacity(0.95),
                      fontWeight: FontWeight.w500,
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
              // Feedback
              const SizedBox(height: 6),
              _FeedbackBar(
                p: p,
                selected: _vote,
                onLike: _onLike,
                onDislike: _onDislike,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  final Palette p;
  final InsightFeedbackVote? selected;
  final Future<void> Function() onLike;
  final Future<void> Function() onDislike;

  const _FeedbackBar({
    required this.p,
    required this.selected,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    final isLike = selected == InsightFeedbackVote.like;
    final isDislike = selected == InsightFeedbackVote.dislike;

    Widget iconButton({
      required bool active,
      required IconData icon,
      required Future<void> Function() onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          await onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: active ? p.accent.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(active ? 999 : 24),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 26,
              color: active
                  ? p.accent.withOpacity(0.95)
                  : p.muted.withOpacity(0.55),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        iconButton(active: isLike, icon: Icons.done_rounded, onTap: onLike),
        const SizedBox(width: 10),
        iconButton(
          active: isDislike,
          icon: Icons.close_rounded,
          onTap: onDislike,
        ),
      ],
    );
  }
}

class _DislikeResult {
  final InsightFeedbackReason reason;
  final String? comment;

  const _DislikeResult({required this.reason, this.comment});
}

Future<_DislikeResult?> _showDislikeReasonSheet(
  BuildContext context, {
  required Palette p,
  InsightFeedbackReason? initialReason,
  String? initialComment,
}) {
  return showModalBottomSheet<_DislikeResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.bg,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _DislikeReasonSheet(
      p: p,
      initialReason: initialReason,
      initialComment: initialComment,
    ),
  );
}

class _DislikeReasonSheet extends StatefulWidget {
  final Palette p;
  final InsightFeedbackReason? initialReason;
  final String? initialComment;

  const _DislikeReasonSheet({
    required this.p,
    this.initialReason,
    this.initialComment,
  });

  @override
  State<_DislikeReasonSheet> createState() => _DislikeReasonSheetState();
}

class _DislikeReasonSheetState extends State<_DislikeReasonSheet> {
  InsightFeedbackReason? _reason;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason = widget.initialReason;
    final c = (widget.initialComment ?? '').trim();
    if (c.isNotEmpty) {
      _controller.text = c;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _label(InsightFeedbackReason r) {
    switch (r) {
      case InsightFeedbackReason.tooObvious:
        return '너무 당연해요';
      case InsightFeedbackReason.duplicate:
        return '비슷한 내용을 자주 봐요';
      case InsightFeedbackReason.tooSharp:
        return '표현이 너무 단정적이에요';
      case InsightFeedbackReason.notRelevant:
        return '나와 관련이 적어요';
      case InsightFeedbackReason.badTiming:
        return '지금은 타이밍이 아니에요';
      case InsightFeedbackReason.other:
        return '기타';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    Widget option(InsightFeedbackReason r) {
      final selected = _reason == r;

      return InkWell(
        onTap: () {
          // Most reasons submit immediately.
          if (r != InsightFeedbackReason.other) {
            Navigator.of(context).pop(_DislikeResult(reason: r));
          } else {
            setState(() => _reason = InsightFeedbackReason.other);
          }
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _label(r),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: selected
                    ? GlassDot(size: 12, color: p.accent, active: false)
                    : const SizedBox(width: 12),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          6,
          18,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Text(
                '어떤 점이 아쉬웠나요?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            option(InsightFeedbackReason.tooObvious),
            option(InsightFeedbackReason.duplicate),
            option(InsightFeedbackReason.tooSharp),
            option(InsightFeedbackReason.notRelevant),
            option(InsightFeedbackReason.badTiming),
            option(InsightFeedbackReason.other),

            if (_reason == InsightFeedbackReason.other) ...[
              const SizedBox(height: 0),
              TextField(
                controller: _controller,
                maxLines: 2,
                minLines: 1,
                cursorColor: p.accent,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final comment = _controller.text.trim();
                  Navigator.of(context).pop(
                    _DislikeResult(
                      reason: InsightFeedbackReason.other,
                      comment: comment.isEmpty ? null : comment,
                    ),
                  );
                },
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: p.ink.withOpacity(0.92),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.only(top: 6, bottom: 6),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: p.outline.withOpacity(0.85),
                      width: 1,
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: p.outline.withOpacity(0.85),
                      width: 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: p.accent.withOpacity(0.9),
                      width: 1,
                    ),
                  ),
                  hintText: '남겨주면 다음 인사이트가 더 정확해져요',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.muted.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
                  counterText: '',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showInsightDetailSheet(
  BuildContext context, {
  required Palette p,
  required InsightPreviewUi item,
  fb_api.InsightFeedbackApiClient? feedbackApi,
  InsightFeedbackSubmit? onSubmitFeedback,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.bg,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => InsightDetailSheet(
      p: p,
      item: item,
      feedbackApi: feedbackApi,
      onSubmitFeedback: onSubmitFeedback,
    ),
  );
}

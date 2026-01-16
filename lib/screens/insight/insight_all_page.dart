import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/insight_api_client.dart';
import 'package:lifelog_mobile/api/insight_feedback_api_client.dart';

import 'widgets/insight_detail_sheet.dart';

// ✅ 공통 헤더
import 'package:lifelog_mobile/widgets/app_page_header.dart';

import 'package:lifelog_mobile/widgets/app_safe_area.dart';
import 'package:lifelog_mobile/widgets/glass_dot.dart';

class InsightsAllPage extends StatefulWidget {
  final Palette p;
  final Color bg;
  final VoidCallback onLogout;

  const InsightsAllPage({
    super.key,
    required this.p,
    required this.bg,
    required this.onLogout,
  });

  @override
  State<InsightsAllPage> createState() => _InsightsAllPageState();
}

class _InsightsAllPageState extends State<InsightsAllPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final AuthApiClient _authApi;
  late final InsightApiClient _insightApi;
  late final InsightFeedbackApiClient _feedbackApi;

  String? _cursor;
  bool _hasMore = true;

  bool _loading = false;
  String? _error;
  List<InsightPreviewUi> _items = <InsightPreviewUi>[];

  @override
  void initState() {
    super.initState();
    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _secureStorage,
      onUnauthorized: widget.onLogout,
    );
    _insightApi = InsightApiClient(_authApi);
    _feedbackApi = InsightFeedbackApiClient(_authApi);
    _load();
  }

  Future<void> _load({bool loadMore = false}) async {
    if (_loading) return;
    if (loadMore && !_hasMore) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await _insightApi.getInsightsPage(limit: 50, cursor: loadMore ? _cursor : null);

      // Map API model -> UI model (keep id)
      final nextItems = page.items
          .map<InsightPreviewUi>((it) => InsightPreviewUi(
                id: it.id,
                kind: _kindFromServer(it.kind),
                title: it.title,
                body: it.body,
                evidence: it.evidence,
              ))
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _items = [..._items, ...nextItems];
        } else {
          _items = nextItems;
        }
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '불러오지 못했어요';
        _loading = false;
      });
    }
  }

  void _openDetail(InsightPreviewUi item) {
    showInsightDetailSheet(
      context,
      p: widget.p,
      item: item,
      feedbackApi: _feedbackApi,
    );
  }

  String _labelFor(InsightKindUi kind) {
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

  InsightKindUi _kindFromServer(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'TENDENCY':
        return InsightKindUi.tendency;
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
      default:
        return InsightKindUi.pattern;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    return Scaffold(
      backgroundColor: widget.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: AppPageHeader(title: '', titleColor: p.ink, iconColor: p.ink),
      ),
      body: AppSafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                children: [
                  // 1) If we already have items, always render them first.
                  if (_items.isNotEmpty)
                    for (int i = 0; i < _items.length; i++) ...[
                      _InsightRow(
                        p: p,
                        item: _items[i],
                        label: _labelFor(_items[i].kind),
                        onTap: () => _openDetail(_items[i]),
                      ),
                      if (i != _items.length - 1) const SizedBox(height: 10),
                    ]
                  // 2) Otherwise render empty/loading/error states.
                  else if (_loading)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '불러오는 중…',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: p.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: p.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '아직 인사이트가 없어요',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: p.muted.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (!_loading && _hasMore) ...[
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => _load(loadMore: true),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '더 불러오기',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: p.muted,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final Palette p;
  final InsightPreviewUi item;
  final String label;
  final VoidCallback onTap;

  const _InsightRow({
    required this.p,
    required this.item,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: GlassDot(size: 8, color: p.accent, active: false),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: p.accent.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: p.ink,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

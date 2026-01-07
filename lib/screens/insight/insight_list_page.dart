import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/insight_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/models/ai_insight_item.dart';
import 'package:lifelog_mobile/theme/palette.dart';

class InsightListPage extends StatefulWidget {
  final VoidCallback onLogout;
  final String keyword; // grouping key (can be "전체" for null)

  const InsightListPage({
    super.key,
    required this.onLogout,
    required this.keyword,
  });

  @override
  State<InsightListPage> createState() => _InsightListPageState();
}

class _InsightListPageState extends State<InsightListPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  late final AuthApiClient _authApi;
  late final InsightApiClient _insightApi;

  final ScrollController _scroll = ScrollController();

  bool _loading = false; // first load or refresh
  bool _loadingMore = false;
  String? _error;

  List<AiInsightItem> _items = const [];
  String? _nextCursor;

  @override
  void initState() {
    super.initState();

    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _secureStorage,
      onUnauthorized: widget.onLogout,
    );
    _insightApi = InsightApiClient(_authApi);

    _scroll.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  bool _matchKeyword(AiInsightItem x) {
    final keyword = widget.keyword;
    if (keyword == '전체') {
      // 기존 의도: "전체"는 keyword가 null/empty인 그룹
      return (x.keyword == null || x.keyword!.trim().isEmpty);
    }
    return (x.keyword ?? '').trim() == keyword;
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_loading || _loadingMore) return;
    if (_nextCursor == null || _nextCursor!.trim().isEmpty) return;

    // 하단 근처에서 load more
    final threshold = 240.0;
    final max = _scroll.position.maxScrollExtent;
    final now = _scroll.position.pixels;
    if (now >= (max - threshold)) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _items = const [];
      _nextCursor = null;
    });

    try {
      final page = await _insightApi.getInsightsPage(limit: 30);

      final filtered = page.items.where(_matchKeyword).toList();

      if (!mounted) return;
      setState(() {
        _items = filtered;
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '불러오지 못했어요';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final cursor = _nextCursor;
    if (cursor == null || cursor.trim().isEmpty) return;

    setState(() {
      _loadingMore = true;
      _error = null;
    });

    try {
      final page = await _insightApi.getInsightsPage(limit: 30, cursor: cursor);
      final incoming = page.items.where(_matchKeyword).toList();

      // 서버가 중복을 주는 경우를 방어 (id가 없으면 title+body로 최소 방어)
      final existingKey = <String>{};
      for (final x in _items) {
        existingKey.add(_dedupKey(x));
      }

      final merged = [..._items];
      for (final x in incoming) {
        final k = _dedupKey(x);
        if (!existingKey.contains(k)) {
          existingKey.add(k);
          merged.add(x);
        }
      }

      if (!mounted) return;
      setState(() {
        _items = merged;
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = '불러오지 못했어요';
      });
    }
  }

  String _dedupKey(AiInsightItem x) {
    // AiInsightItem에 id가 있으면 그걸 쓰는 게 가장 안전합니다.
    // 여기서는 모델을 모른다고 가정하고 방어적으로 구성합니다.
    final id = (x as dynamic).id;
    if (id != null) return 'id:$id';
    return 't:${x.title.trim()}|b:${x.body.trim()}';
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);

    final showEmpty = !_loading && _error == null && _items.isEmpty;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: p.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.keyword,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: p.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFirst,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            children: [
              if (_loading)
                Text(
                  '불러오는 중…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (_error != null)
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (showEmpty)
                Text(
                  '아직 인사이트가 없어요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else ...[
                for (int i = 0; i < _items.length; i++) ...[
                  _InsightCard(p: p, item: _items[i]),
                  if (i != _items.length - 1) const SizedBox(height: 14),
                ],
                const SizedBox(height: 14),
                if (_loadingMore)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '더 불러오는 중…',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: p.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else if (_nextCursor != null && _nextCursor!.trim().isNotEmpty)
                  // 스크롤이 짧아서 하단 감지가 안 될 때를 대비한 수동 버튼
                  Center(
                    child: TextButton(
                      onPressed: _loadMore,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: Text(
                        '더 보기',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: p.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Palette p;
  final AiInsightItem item;

  const _InsightCard({required this.p, required this.item});

  @override
  Widget build(BuildContext context) {
    final evidence = (item.evidence ?? '').trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: p.ink.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: p.ink,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: p.muted,
              fontWeight: FontWeight.w600,
              height: 1.55,
              fontSize: 16,
            ),
          ),
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              evidence,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: p.muted.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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

  bool _loading = false;
  String? _error;
  List<AiInsightItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _secureStorage,
      onUnauthorized: widget.onLogout,
    );
    _insightApi = InsightApiClient(_authApi);

    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final all = await _insightApi.getInsights(limit: 30);
      final keyword = widget.keyword;

      final filtered = (keyword == '전체')
          ? all.where((x) => x.keyword == null || x.keyword!.trim().isEmpty).toList()
          : all.where((x) => (x.keyword ?? '').trim() == keyword).toList();

      if (!mounted) return;
      setState(() {
        _items = filtered;
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

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: _loading
              ? Text(
                  '불러오는 중…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted,
                        fontWeight: FontWeight.w600,
                      ),
                )
              : (_error != null)
                  ? Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: p.muted,
                            fontWeight: FontWeight.w600,
                          ),
                    )
                  : (_items.isEmpty)
                      ? Text(
                          '아직 인사이트가 없어요',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: p.muted,
                                fontWeight: FontWeight.w600,
                              ),
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            return _InsightCard(p: p, item: item);
                          },
                        ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Palette p;
  final AiInsightItem item;

  const _InsightCard({
    required this.p,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
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
          if ((item.evidence ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.evidence!.trim(),
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
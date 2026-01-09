// lib/screens/home/main_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/theme/theme_provider.dart';

import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/home_api_client.dart';

import '../record/record_screen.dart';
import '../settings/settings_home_page.dart';
import '../settings/settings_routes.dart';

import 'log_all_page.dart';
import 'log_models.dart';

import 'package:lifelog_mobile/screens/insight/insight_all_page.dart';
import 'package:lifelog_mobile/screens/insight/widgets/insight_detail_sheet.dart';
import 'package:lifelog_mobile/widgets/app_safe_area.dart';

import 'package:lifelog_mobile/widgets/glass_fab.dart';
import 'package:lifelog_mobile/widgets/glass_dot.dart';
import 'package:lifelog_mobile/widgets/glass_chevron_button.dart';

String _formatKoreanDate(DateTime dt) => '${dt.month}월 ${dt.day}일';

class MainPage extends StatefulWidget {
  final Color bg;
  final Palette p;
  final VoidCallback onLogout;

  const MainPage({
    super.key,
    required this.bg,
    required this.p,
    required this.onLogout,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // API
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final AuthApiClient _authApi;
  late final HomeApiClient _homeApi;

  bool _loadingHome = false;
  String? _homeError;
  _HomeVm? _home;

  @override
  void initState() {
    super.initState();
    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _secureStorage,
      onUnauthorized: widget.onLogout,
    );
    _homeApi = HomeApiClient(_authApi);
    _loadHome();
  }

  Future<void> _loadHome() async {
    if (_loadingHome) return;
    setState(() {
      _loadingHome = true;
      _homeError = null;
    });

    try {
      final map = await _homeApi.getHome(limitLogs: 3, limitInsights: 2);

      final vm = _HomeVm.fromJson(map);
      if (!mounted) return;
      setState(() {
        _home = vm;
        _loadingHome = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _homeError = '불러오지 못했어요';
        _loadingHome = false;
      });
    }
  }

  void _openAllLogs() {
    final p = widget.p;
    final bg = widget.bg;

    pushSettingsPage<void>(
      context,
      AllLogsPage(p: p, bg: bg, onLogout: widget.onLogout),
    );
  }

  void _openAllInsights() {
    final p = widget.p;
    final bg = widget.bg;

    pushSettingsPage<void>(
      context,
      InsightsAllPage(p: p, bg: bg, onLogout: widget.onLogout),
    );
  }

  Future<void> _openInsightDetail(InsightPreviewUi item) async {
    await showInsightDetailSheet(context, p: widget.p, item: item);
  }

  Future<void> _openRecord() async {
    final onLogout = widget.onLogout;

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RecordScreen(onLogout: onLogout)));
    if (!mounted) return;
    _loadHome();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final bg = widget.bg;
    final onLogout = widget.onLogout;

    final vm = _home;
    final showInitialLoading = _loadingHome && vm == null;
    final showError = _homeError != null;

    final topInsight =
        vm?.topInsight ??
        _TopInsightPreview(
          date: DateTime.now(),
          headline: showInitialLoading
              ? '불러오는 중…'
              : (_homeError ?? '아직 해석할 신호가 충분하지 않아요'),
          signalCount: 0,
          axes: const [],
          lastTimeLabel: '—',
        );

    final rawHeadline = topInsight.headline.trim();
    final isDefaultHeadline =
        rawHeadline.isEmpty ||
        rawHeadline == '아직 해석할 신호가 충분하지 않아요' ||
        rawHeadline == '아직 해석할 신호가 충분하지 않아요.';

    final effectiveHeadline = isDefaultHeadline
        ? (topInsight.signalCount == 0
              ? '아직 해석할 신호가 충분하지 않아요'
              : (topInsight.signalCount <= 2
                    ? '작은 신호가 관측되고 있어요'
                    : '특정 패턴이 감지되고 있어요'))
        : rawHeadline;

    final insights = vm?.insights ?? const <InsightPreviewUi>[];
    final visibleInsights = insights.take(2).toList();
    final logs = vm?.recentLogs ?? const <LogPreview>[];

    // 헤더 점은 “활성 상태일 때만” 은은하게
    final headerDotActive = !showInitialLoading && !showError;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AppSafeArea(
        //minimum: const EdgeInsets.only(bottom: 0),
        child: Transform.translate(
          offset: const Offset(0, 351),
          child: Center(
            child: GlassFab(
              onPressed: _openRecord,
              enabled: true,
              color: p.accent,

              // ✅ checksoft 감각 통일
              size: 72,
              lighten: 0.06,
              pressedScale: 0.98,
              floatEnabled: false,
            ),
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: Icon(Icons.menu, color: p.ink.withOpacity(0.7), size: 30),
            tooltip: '설정',
            onPressed: () {
              pushSettingsPage<void>(
                context,
                SettingsHomePage(
                  onChangeTheme: (m) =>
                      context.read<ThemeProvider>().setMode(m),
                  onLogout: onLogout,
                ),
                fromLeft: true,
              );
            },
          ),
        ),
      ),

      body: AppSafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            _SectionHeader(
              title: _formatKoreanDate(topInsight.date),
              subtitle: effectiveHeadline,
              p: p,
              dotActive: headerDotActive,
            ),
            const SizedBox(height: 14),
            _TopInsightCard(p: p, items: topInsight),
            const SizedBox(height: 18),

            // ---- Insights header (우측: glass chevron) ----
            Row(
              children: [
                Expanded(
                  child: Text(
                    '인사이트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: p.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                GlassChevronButton(accent: p.accent, onTap: _openAllInsights),
              ],
            ),
            const SizedBox(height: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showInitialLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '불러오는 중…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  )
                else if (showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '연결이 원활하지 않아요.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  )
                else if (insights.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    child: Text(
                      (topInsight.signalCount == 0)
                          ? '인사이트를 생성 중이에요'
                          : '신호를 연결하고 있어요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < visibleInsights.length; i++) ...[
                    _AiInsightRow(
                      p: p,
                      item: visibleInsights[i],
                      onTap: () => _openInsightDetail(visibleInsights[i]),
                    ),
                    if (i != visibleInsights.length - 1)
                      const SizedBox(height: 10),
                  ],
              ],
            ),

            const SizedBox(height: 20),

            // ---- Logs header (우측: glass chevron) ----
            Row(
              children: [
                Expanded(
                  child: Text(
                    '기록',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: p.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                GlassChevronButton(accent: p.accent, onTap: _openAllLogs),
              ],
            ),
            const SizedBox(height: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showInitialLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '불러오는 중…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  )
                else if (showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '연결이 원활하지 않아요.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  )
                else if (logs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '아직 기록이 없어요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.muted.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  )
                else
                  _RecentLogsCard(p: p, logs: logs, onTapLog: null),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AiInsightRow extends StatelessWidget {
  final Palette p;
  final InsightPreviewUi item;
  final VoidCallback? onTap;

  const _AiInsightRow({required this.p, required this.item, this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(item.kind);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
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
                                letterSpacing: -0.1,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Palette p;
  final bool dotActive;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.p,
    required this.dotActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: p.ink,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            GlassDot(size: 8, color: p.accent, active: dotActive),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: p.muted.withOpacity(0.9),
              fontWeight: FontWeight.w500,
              height: 1.45,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}

class _TopInsightPreview {
  final DateTime date;
  final String headline;
  final int signalCount;
  final List<String> axes;
  final String lastTimeLabel;

  const _TopInsightPreview({
    required this.date,
    required this.headline,
    required this.signalCount,
    required this.axes,
    required this.lastTimeLabel,
  });
}

class _TopInsightCard extends StatelessWidget {
  final Palette p;
  final _TopInsightPreview items;

  const _TopInsightCard({required this.p, required this.items});

  @override
  Widget build(BuildContext context) {
    final keywordLine = items.axes.isEmpty
        ? null
        : items.axes.take(4).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${items.signalCount}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w600,
                  height: 0.95,
                  fontSize: 42,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '관측된 신호',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  items.lastTimeLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (keywordLine != null) ...[
            const SizedBox(height: 8),
            Text(
              keywordLine,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: p.muted,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _RecentLogsCard extends StatelessWidget {
  final Palette p;
  final List<LogPreview> logs;
  final void Function(int index)? onTapLog;

  const _RecentLogsCard({
    required this.p,
    required this.logs,
    required this.onTapLog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < logs.length; i++) ...[
          _RecentLogRow(
            p: p,
            item: logs[i],
            isLast: i == logs.length - 1,
            onTap: onTapLog == null ? null : () => onTapLog!(i),
          ),
          if (i != logs.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RecentLogRow extends StatelessWidget {
  final Palette p;
  final LogPreview item;
  final bool isLast;
  final VoidCallback? onTap;

  const _RecentLogRow({
    required this.p,
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 74,
              child: Text(
                item.timeLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- API View-models ---
class _HomeVm {
  final _TopInsightPreview topInsight;
  final List<InsightPreviewUi> insights;
  final List<LogPreview> recentLogs;

  const _HomeVm({
    required this.topInsight,
    required this.insights,
    required this.recentLogs,
  });

  static _HomeVm fromJson(Map<String, dynamic> map) {
    final top =
        (map['topInsight'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final topDateStr = (top['date'] as String?) ?? '';
    DateTime date;
    try {
      date = DateTime.parse(topDateStr);
    } catch (_) {
      date = DateTime.now();
    }

    final topInsight = _TopInsightPreview(
      date: date,
      headline: (top['headline'] as String?)?.trim().isNotEmpty == true
          ? (top['headline'] as String).trim()
          : '아직 해석할 신호가 충분하지 않아요',
      signalCount: (top['signalCount'] as num?)?.toInt() ?? 0,
      axes: ((top['axes'] as List?) ?? const []).whereType<String>().toList(),
      lastTimeLabel:
          (top['lastTimeLabel'] as String?)?.trim().isNotEmpty == true
          ? (top['lastTimeLabel'] as String).trim()
          : '—',
    );

    final insightsRaw = (map['insights'] as List?) ?? const [];
    final insights = insightsRaw
        .whereType<Map>()
        .map((m) => InsightPreviewUi.fromJson(m.cast<String, dynamic>()))
        .toList();

    final logsRaw = (map['recentLogs'] as List?) ?? const [];
    final recentLogs = logsRaw
        .whereType<Map>()
        .map((m) => LogPreview.fromJson(m.cast<String, dynamic>()))
        .toList();

    return _HomeVm(
      topInsight: topInsight,
      insights: insights,
      recentLogs: recentLogs,
    );
  }
}

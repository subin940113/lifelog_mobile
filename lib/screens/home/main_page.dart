import 'package:flutter/material.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import '../record/record_screen.dart';
import '../settings/settings_home_page.dart';
import '../settings/settings_routes.dart';
import 'package:provider/provider.dart';

import 'package:lifelog_mobile/theme/theme_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/api/home_api_client.dart';


String _formatKoreanDate(DateTime dt) {
  // Local time (device). Example: "1월 1일"
  return '${dt.month}월 ${dt.day}일';
}



enum _InsightKind { tendency, cause, forecast, action }

enum _InsightPeriod { day, week, month }

class _InsightPreview {
  final _InsightKind kind;
  final String title;
  final String body;
  final String? evidence; // short “because” line

  const _InsightPreview({
    required this.kind,
    required this.title,
    required this.body,
    this.evidence,
  });

  static _InsightKind _kindFrom(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'TENDENCY':
        return _InsightKind.tendency;
      case 'CAUSE':
        return _InsightKind.cause;
      case 'FORECAST':
        return _InsightKind.forecast;
      case 'ACTION':
        return _InsightKind.action;
      default:
        return _InsightKind.tendency;
    }
  }

  factory _InsightPreview.fromJson(Map<String, dynamic> m) {
    return _InsightPreview(
      kind: _kindFrom(m['kind'] as String?),
      title: (m['title'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      evidence: (m['evidence'] as String?),
    );
  }
}

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
  _InsightPeriod _period = _InsightPeriod.day;

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

  String _periodParam(_InsightPeriod p) {
    switch (p) {
      case _InsightPeriod.day:
        return 'day';
      case _InsightPeriod.week:
        return 'week';
      case _InsightPeriod.month:
        return 'month';
    }
  }

  Future<void> _loadHome() async {
    if (_loadingHome) return;
    setState(() {
      _loadingHome = true;
      _homeError = null;
    });

    try {
      final period = _periodParam(_period);
      final map = await _homeApi.getHome(
        period: period,
        limitLogs: 3,
        limitInsights: 2,
      );
      final vm = _HomeVm.fromJson(map);
      if (!mounted) return;
      setState(() {
        _home = vm;
        _loadingHome = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _homeError = '불러오지 못했어요';
        _loadingHome = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final bg = widget.bg;
    final onLogout = widget.onLogout;

    final vm = _home;

    final topInsight = vm?.topInsight ?? _TopInsightPreview(
          date: DateTime.now(),
          headline: _loadingHome ? '불러오는 중…' : (_homeError ?? '아직 해석할 신호가 충분하지 않아요'),
          signalCount: 0,
          axes: const [],
          lastTimeLabel: '—',
        );

    final rawHeadline = topInsight.headline.trim();
    final isDefaultHeadline = rawHeadline.isEmpty ||
        rawHeadline == '아직 해석할 신호가 충분하지 않아요' ||
        rawHeadline == '아직 해석할 신호가 충분하지 않아요.';

    final effectiveHeadline = isDefaultHeadline
        ? (topInsight.signalCount == 0
            ? '아직 해석할 신호가 충분하지 않아요'
            : (topInsight.signalCount <= 2
                ? '작은 신호가 관측되고 있어요'
                : '특정 패턴이 감지되고 있어요'))
        : rawHeadline;

    final recentLogs = vm?.recentLogs ?? const <_LogPreview>[
          _LogPreview(timeLabel: '—', preview: '불러오는 중…'),
        ];

    final insights = vm?.insights ?? const <_InsightPreview>[];
    final visibleInsights = insights.take(2).toList();

    return Scaffold(
      backgroundColor: widget.bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RecordFab(
        enabled: true,
        p: p,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RecordScreen(onLogout: onLogout)),
          );
          if (!mounted) return;
          _loadHome();
        },
      ),
      appBar: AppBar(
        backgroundColor: widget.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: p.ink),
          tooltip: '설정',
          onPressed: () {
            pushSettingsPage<void>(
              context,
              SettingsHomePage(
                onChangeTheme: (m) => context.read<ThemeProvider>().setMode(m),
                onLogout: onLogout,
              ),
              fromLeft: true,
            );
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            _SectionHeader(
              title: _formatKoreanDate(topInsight.date),
              subtitle: effectiveHeadline,
              p: p,
            ),
            const SizedBox(height: 14),
            _TopInsightCard(
              p: p,
              items: topInsight,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '인사이트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: p.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: -0.1,
                        ),
                  ),
                ),
                _InsightPeriodSwitch(
                  p: p,
                  period: _period,
                  onChanged: (v) {
                    setState(() => _period = v);
                    _loadHome();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200, // reserve space for up to 2 insight rows
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_loadingHome && vm == null)
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
                  else if (_homeError != null)
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
                    Expanded(
                      child: Center(
                        child: Text(
                          (topInsight.signalCount == 0)
                              ? '인사이트를 생성 중이에요'
                              : (topInsight.signalCount <= 2 ? '신호를 연결하고 있어요' : '인사이트를 생성 중이에요'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: p.muted.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < visibleInsights.length; i++) ...[
                      _AiInsightRow(
                        p: p,
                        item: visibleInsights[i],
                      ),
                      if (i != visibleInsights.length - 1)
                        const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitleRow(
              title: '기록',
              trailing: '전체 보기',
              p: p,
              onTap: () {
                // TODO: 타임라인 페이지로 이동
                // Navigator.of(context).push(...);
              },
            ),
            const SizedBox(height: 8),
            _RecentLogsCard(
              p: p,
              logs: recentLogs,
              onTapLog: null,
            ),
            // Removed hint row, FAB is visible.
          ],
        ),
      ),
    );
  }
}
class _InsightPeriodSwitch extends StatelessWidget {
  final Palette p;
  final _InsightPeriod period;
  final ValueChanged<_InsightPeriod> onChanged;

  const _InsightPeriodSwitch({
    required this.p,
    required this.period,
    required this.onChanged,
  });

  Widget _item(BuildContext context, String label, _InsightPeriod value) {
    final active = period == value;
    final fg = active ? p.accent : p.muted;

    return InkWell(
      onTap: () => onChanged(value),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (active)
              Positioned(
                bottom: -1,
                child: Container(
                  height: 2,
                  width: 18,
                  decoration: BoxDecoration(
                    color: p.accent.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _item(context, '오늘', _InsightPeriod.day),
        _item(context, '주간', _InsightPeriod.week),
        _item(context, '월간', _InsightPeriod.month),
      ],
    );
  }
}

class _AiInsightRow extends StatelessWidget {
  final Palette p;
  final _InsightPreview item;

  const _AiInsightRow({
    required this.p,
    required this.item,
  });

  String _labelFor(_InsightKind kind) {
    switch (kind) {
      case _InsightKind.tendency:
        return '성향';
      case _InsightKind.cause:
        return '원인';
      case _InsightKind.forecast:
        return '예측';
      case _InsightKind.action:
        return '추천';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(item.kind);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: p.accent.withOpacity(0.85),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: p.ink,
                                fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class RecordFab extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final Palette p;

  const RecordFab({
    super.key,
    required this.enabled,
    required this.onPressed,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFFFFFFFF);

    // Same visual tone as DoneFab (record page)
    final enabledBg = Color.lerp(p.accent, Colors.white, 0.18)!;
    final disabledBg = enabledBg.withOpacity(0.38);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 24),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          opacity: enabled ? 1.0 : 0.32,
          child: IgnorePointer(
            ignoring: !enabled,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkResponse(
                onTap: onPressed,
                radius: 40,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: enabled ? enabledBg : disabledBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: fg,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Palette p;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.p,
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
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
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
                  fontSize: 15,
                ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  final String title;
  final String trailing;
  final Palette p;
  final VoidCallback? onTap;

  const _SectionTitleRow({
    required this.title,
    required this.trailing,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trailingColor = onTap == null ? p.muted : p.accent;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.1,
                ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailing,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: trailingColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopInsightPreview {
  final DateTime date;
  final String headline; // server-driven
  final int signalCount; // server-driven
  final List<String> axes; // server-driven
  final String lastTimeLabel; // server-driven

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

  const _TopInsightCard({
    required this.p,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final keywordLine = items.axes.isEmpty ? null : items.axes.take(4).join(' · ');
    final hint = null;

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
                      fontWeight: FontWeight.w700,
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
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
            ),
          ] else if (keywordLine != null) ...[
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Palette p;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.ink.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: p.muted,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Palette p;

  const _Chip({
    required this.text,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    final bg = p.ink.withOpacity(0.04);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: p.ink,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Palette p;
  final String title;
  final String body;

  const _InsightCard({
    required this.p,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: p.ink,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: p.muted,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogPreview {
  final String timeLabel;
  final String preview;

  const _LogPreview({
    required this.timeLabel,
    required this.preview,
  });

  factory _LogPreview.fromJson(Map<String, dynamic> m) {
    return _LogPreview(
      timeLabel: (m['timeLabel'] as String?) ?? '—',
      preview: (m['preview'] as String?) ?? '',
    );
  }
}

class _RecentLogsCard extends StatelessWidget {
  final Palette p;
  final List<_LogPreview> logs;
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
        ],
      ],
    );
  }
}

class _RecentLogRow extends StatelessWidget {
  final Palette p;
  final _LogPreview item;
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
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 74,
              child: Text(
                item.timeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      fontSize: 16,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftHintRow extends StatelessWidget {
  final Palette p;
  final String text;

  const _SoftHintRow({
    required this.p,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
          ),
        ),
      ],
    );
  }
}
// --- API View-models and JSON parsing ---

class _HomeVm {
  final _TopInsightPreview topInsight;
  final List<_InsightPreview> insights;
  final List<_LogPreview> recentLogs;

  const _HomeVm({
    required this.topInsight,
    required this.insights,
    required this.recentLogs,
  });

  static _HomeVm fromJson(Map<String, dynamic> map) {
    final top = (map['topInsight'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final topDateStr = (top['date'] as String?) ?? '';
    DateTime date;
    try {
      // Expect yyyy-MM-dd
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
      lastTimeLabel: (top['lastTimeLabel'] as String?)?.trim().isNotEmpty == true
          ? (top['lastTimeLabel'] as String).trim()
          : '—',
    );

    final insightsRaw = (map['insights'] as List?) ?? const [];
    final insights = insightsRaw
        .whereType<Map>()
        .map((m) => _InsightPreview.fromJson(m.cast<String, dynamic>()))
        .toList();

    final logsRaw = (map['recentLogs'] as List?) ?? const [];
    final recentLogs = logsRaw
        .whereType<Map>()
        .map((m) => _LogPreview.fromJson(m.cast<String, dynamic>()))
        .toList();

    return _HomeVm(topInsight: topInsight, insights: insights, recentLogs: recentLogs);
  }
}

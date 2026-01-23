// lib/screens/home/main_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/theme/theme_provider.dart';

import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/home_api_client.dart';
import 'package:lifelog_mobile/api/insight_feedback_api_client.dart';
import 'package:lifelog_mobile/api/insight_api_client.dart';
import 'package:lifelog_mobile/api/signal_api_client.dart';

import '../record/record_screen.dart';
import '../settings/settings_home_page.dart';
import '../settings/settings_routes.dart';

import 'log_all_page.dart';
import 'log_models.dart';

import 'package:lifelog_mobile/screens/insight/insight_all_page.dart';
import 'package:lifelog_mobile/screens/insight/widgets/insight_detail_sheet.dart';

import 'package:lifelog_mobile/widgets/glass_dot.dart';
import 'package:lifelog_mobile/widgets/glass_menu_button.dart';

import 'widgets/signal_object_card.dart';
import 'widgets/signal_object_section.dart';
import 'widgets/hand_drawn_wave_divider.dart';

String _formatKoreanDate(DateTime dt) => '${dt.month}월 ${dt.day}일';

enum _MainTab { log, insight }

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

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  _MainTab _currentTab = _MainTab.log;

  // Storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // API
  late final AuthApiClient _authApi;
  late final HomeApiClient _homeApi;

  InsightFeedbackApiClient? _insightFeedbackApi;

  InsightFeedbackApiClient get _feedbackApi {
    return _insightFeedbackApi ??= InsightFeedbackApiClient(_authApi);
  }

  // ✅ Signal API (SignalObjectSection에서만 사용)
  // SignalApiClient는 AuthApiClient를 래핑하며, Authorization/refresh는 AuthApiClient가 처리함
  late final SignalApiClient _signalClient;

  // Insight API (인사이트 설정 상태 확인용)
  late final InsightApiClient _insightApi;

  // Home state
  bool _loadingHome = false;
  String? _homeError;
  _HomeVm? _home;

  // Insight settings state
  bool? _insightEnabled; // null = 로딩 중, true/false = 로드 완료

  bool _wasInBackground = false;
  bool _isFirstBuild = true;

  // SignalObjectSection 재생성을 위한 Key
  // 다른 페이지에서 돌아올 때마다 변경하여 위젯을 재생성하고 API를 다시 호출
  int _signalSectionKey = 0;

  @override
  void initState() {
    super.initState();

    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _secureStorage,
      onUnauthorized: widget.onLogout,
    );
    _homeApi = HomeApiClient(_authApi);

    WidgetsBinding.instance.addObserver(this);

    _signalClient = SignalApiClient(_authApi);
    _insightApi = InsightApiClient(_authApi);

    _loadHome();
    _loadInsightSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _loadHome();
      // SignalObjectSection 재생성을 위해 Key 변경
      setState(() {
        _signalSectionKey++;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isFirstBuild) {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadHome();
            // 설정 페이지에서 돌아올 때 인사이트 설정 상태도 다시 로드 (캐시 방지)
            _loadInsightSettings();
            // 모달 닫힘 등으로 인한 didChangeDependencies에서는 SignalObjectSection 재생성하지 않음
            // 실제 페이지 이동 후 돌아올 때는 _openRecord 등에서 직접 처리
          }
        });
      }
    } else {
      _isFirstBuild = false;
    }
  }

  Future<void> _loadHome() async {
    if (_loadingHome) return;

    setState(() {
      _loadingHome = true;
      _homeError = null;
    });

    try {
      final map = await _homeApi.getHome(limitLogs: 5, limitInsights: 3);
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

  Future<void> _loadInsightSettings() async {
    try {
      final settings = await _insightApi.getSettings();
      if (!mounted) return;
      setState(() {
        _insightEnabled = settings.enabled;
      });
    } catch (_) {
      // 실패 시 무시 (기본값 null 유지)
    }
  }

  Future<void> _openAllLogs() async {
    final p = widget.p;
    final bg = widget.bg;

    await pushSettingsPage<void>(
      context,
      AllLogsPage(p: p, bg: bg, onLogout: widget.onLogout),
    );
    // 페이지에서 돌아올 때 인사이트 설정 상태 다시 로드 (설정 변경 가능성)
    if (mounted) {
      await _loadInsightSettings();
    }
  }

  Future<void> _openAllInsights() async {
    final p = widget.p;
    final bg = widget.bg;

    await pushSettingsPage<void>(
      context,
      InsightsAllPage(p: p, bg: bg, onLogout: widget.onLogout),
    );
    // 페이지에서 돌아올 때 인사이트 설정 상태 다시 로드 (설정 변경 가능성)
    if (mounted) {
      await _loadInsightSettings();
    }
  }

  Future<void> _openInsightDetail(InsightPreviewUi item) async {
    await showInsightDetailSheet(
      context,
      p: widget.p,
      item: item,
      feedbackApi: _feedbackApi,
    );
  }

  Future<void> _openRecord() async {
    final onLogout = widget.onLogout;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecordScreen(onLogout: onLogout)),
    );

    if (!mounted) return;
    _loadHome();
    // SignalObjectSection 재생성을 위해 Key 변경
    setState(() {
      _signalSectionKey++;
    });
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
        TopInsightPreview(
          date: DateTime.now(),
          headline: showInitialLoading
              ? '불러오는 중…'
              : (_homeError ?? '아직 해석할 기록이 충분하지 않아요'),
          signalCount: 0,
          axes: const [],
          lastTimeLabel: '—',
        );

    final insights = vm?.insights ?? const <InsightPreviewUi>[];
    final visibleInsights = insights.take(3).toList();
    final logs = vm?.recentLogs ?? const <LogPreview>[];

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Tooltip(
            message: '설정',
            child: GlassMenuButton(
              onTap: () async {
                await pushSettingsPage<void>(
                  context,
                  SettingsHomePage(
                    onChangeTheme: (m) => context.read<ThemeProvider>().setMode(m),
                    onLogout: onLogout,
                  ),
                  fromLeft: true,
                );
                // 설정 페이지에서 돌아올 때 인사이트 설정 상태 다시 로드
                if (mounted) {
                  await _loadInsightSettings();
                }
              },
              icon: Icons.menu_rounded,
              accent: p.ink.withOpacity(0.55),
              iconSize: 30,
              depth: 0.55,
              hitSize: 44,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // 1) 상단 고정 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                color: bg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 0, bottom: 2),
                            child: Center(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: SignalObjectSection(
                                  key: ValueKey(_signalSectionKey),
                                  p: p,
                                  api: _signalClient,
                                  top: topInsight,
                                  onTapObject: _openRecord, // ✅ 중앙 시그널 오브젝트 탭만 기록하기로
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const HandDrawnWaveDivider(waveSeed: 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // 2) 메인 콘텐츠
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      child: _MainTabSwitch(
                        p: p,
                        tab: _currentTab,
                        onChanged: (t) => setState(() => _currentTab = t),
                        onMore: (t) {
                          if (t == _MainTab.log) {
                            _openAllLogs();
                          } else {
                            _openAllInsights();
                          }
                        },
                      ),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (_currentTab == _MainTab.log) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                              child: Builder(
                                builder: (context) {
                                  if (showInitialLoading) {
                                    return Text(
                                      '불러오는 중…',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: p.muted,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                    );
                                  }
                                  if (showError) {
                                    return Text(
                                      '연결이 원활하지 않아요.',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: p.muted,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                    );
                                  }
                                  if (logs.isEmpty) {
                                    return Text(
                                      '아직 기록이 없어요',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: p.muted.withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                    );
                                  }
                                  return _RecentLogsCard(
                                    p: p,
                                    logs: logs,
                                    onTapLog: null,
                                  );
                                },
                              ),
                            ),
                          ],
                          if (_currentTab == _MainTab.insight) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                              child: Builder(
                                builder: (context) {
                                  if (showInitialLoading) {
                                    return Text(
                                      '불러오는 중…',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: p.muted,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                    );
                                  }
                                  if (showError) {
                                    return Text(
                                      '연결이 원활하지 않아요.',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: p.muted,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                    );
                                  }
                                  if (insights.isEmpty) {
                                    String message;
                                    if (_insightEnabled != true) {
                                      message = '인사이트가 비활성화되어 있어요';
                                    } else {
                                      message = (topInsight.signalCount == 0)
                                          ? '아직은 기록이 부족해요'
                                          : '조금 더 기록하면, 흐름이 보여요';
                                    }

                                    return Text(
                                      message,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: p.muted.withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_currentTab == _MainTab.log) {
                                  _openAllLogs();
                                } else {
                                  _openAllInsights();
                                }
                              },
                              child: Text(
                                '전체보기',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: (Theme.of(context).brightness == Brightness.dark
                                              ? Palette.strokeDark
                                              : Palette.strokeLight),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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
  final TopInsightPreview topInsight;
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

    final topInsight = TopInsightPreview(
      date: date,
      headline: (top['headline'] as String?)?.trim().isNotEmpty == true
          ? (top['headline'] as String).trim()
          : '아직 해석할 기록이 충분하지 않아요',
      signalCount: (top['signalCount'] as num?)?.toInt() ?? 0,
      axes: ((top['axes'] as List?) ?? const []).whereType<String>().toList(),
      lastTimeLabel: (top['lastTimeLabel'] as String?)?.trim().isNotEmpty == true
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

class _MainTabSwitch extends StatelessWidget {
  final Palette p;
  final _MainTab tab;
  final ValueChanged<_MainTab> onChanged;
  final void Function(_MainTab tab) onMore;

  const _MainTabSwitch({
    required this.p,
    required this.tab,
    required this.onChanged,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final activeStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: (Theme.of(context).brightness == Brightness.dark
                  ? Palette.strokeDark
                  : Palette.strokeLight)
              .withOpacity(0.92),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        );

    final inactiveStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: p.muted.withOpacity(0.75),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        );

    Widget tabItem(String label, _MainTab value) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Text(
            label,
            style: tab == value ? activeStyle : inactiveStyle,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            tabItem('기록', _MainTab.log),
            const SizedBox(width: 100),
            tabItem('인사이트', _MainTab.insight),
          ],
        ),
      ],
    );
  }
}
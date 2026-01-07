// lib/screens/home/logs_all_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/log_api_client.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/app_page_header.dart';

import 'log_models.dart';

// ✅ Glass 공통 컴포넌트
import 'package:lifelog_mobile/widgets/glass_dot.dart';

class AllLogsPage extends StatefulWidget {
  final Palette p;
  final Color bg;
  final VoidCallback onLogout;

  const AllLogsPage({
    super.key,
    required this.p,
    required this.bg,
    required this.onLogout,
  });

  @override
  State<AllLogsPage> createState() => _AllLogsPageState();
}

class _AllLogsPageState extends State<AllLogsPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final AuthApiClient _authApi;
  late final LogApiClient _logApi;

  final List<LogPreview> _logs = [];
  String? _cursor;
  bool _loading = false;
  bool _initialLoaded = false;
  String? _error;

  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _secureStorage,
      onUnauthorized: widget.onLogout,
    );
    _logApi = LogApiClient(_authApi);

    _loadNext(reset: true);
  }

  Future<void> _loadNext({required bool reset}) async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _cursor = null;
        _logs.clear();
        _initialLoaded = false;
      }
    });

    try {
      final res = await _logApi.getAllLogs(limit: _pageSize, cursor: _cursor);

      final next = res.items.map((m) => LogPreview.fromJson(m)).toList();

      if (!mounted) return;
      setState(() {
        _logs.addAll(next);
        _cursor = res.nextCursor;
        _loading = false;
        _initialLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '불러오지 못했어요';
        _loading = false;
        _initialLoaded = true;
      });
    }
  }

  bool get _hasMore => _cursor != null && _cursor!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final bg = widget.bg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: AppPageHeader(title: '기록', titleColor: p.ink, iconColor: p.ink),
      ),
      body: SafeArea(
        top: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 240) {
              if (_hasMore && !_loading) _loadNext(reset: false);
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            children: [
              if (!_initialLoaded && _loading)
                _StatusText(p: p, text: '불러오는 중…')
              else if (_error != null && _logs.isEmpty)
                _StatusText(p: p, text: _error!)
              else if (_logs.isEmpty)
                _StatusText(p: p, text: '아직 기록이 없어요')
              else ...[
                _GroupedTimeline(p: p, logs: _logs),

                const SizedBox(height: 14),
                if (_loading)
                  _StatusText(p: p, text: '불러오는 중…')
                else if (_hasMore)
                  Center(
                    child: TextButton(
                      onPressed: () => _loadNext(reset: false),
                      style: TextButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                        foregroundColor: p.accent,
                      ),
                      child: Text(
                        '더 보기',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: p.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupedTimeline extends StatelessWidget {
  final Palette p;
  final List<LogPreview> logs;

  const _GroupedTimeline({required this.p, required this.logs});

  @override
  Widget build(BuildContext context) {
    String? lastDate;

    final children = <Widget>[];

    for (final item in logs) {
      final date = item.dateLabel;

      final isNewGroup = (lastDate == null || lastDate != date);
      if (isNewGroup) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 14));
        children.add(_DateHeader(p: p, dateLabel: date));
        children.add(const SizedBox(height: 10));
        lastDate = date;
      }

      children.add(_TimelineLogRow(p: p, item: item));
      children.add(const SizedBox(height: 10));
    }

    if (children.isNotEmpty) children.removeLast();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _DateHeader extends StatelessWidget {
  final Palette p;
  final String dateLabel;

  const _DateHeader({required this.p, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: p.ink,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(width: 8),

        // ✅ 기존 단색 점 → GlassDot
        GlassDot(
          size: 6,
          color: p.accent,
          active: false, // 날짜 헤더는 애니메이션 없이 “질감”만
        ),
      ],
    );
  }
}

class _StatusText extends StatelessWidget {
  final Palette p;
  final String text;

  const _StatusText({required this.p, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: p.muted.withOpacity(0.75),
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Row: [시간] [본문]
class _TimelineLogRow extends StatelessWidget {
  final Palette p;
  final LogPreview item;

  const _TimelineLogRow({required this.p, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              item.timeLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: p.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.preview,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: p.ink,
                fontWeight: FontWeight.w500,
                height: 1.55,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

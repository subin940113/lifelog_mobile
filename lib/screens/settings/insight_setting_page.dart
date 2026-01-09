// lib/screens/settings/insight/insight_hub_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/insight_api_client.dart';
import 'package:lifelog_mobile/api/interest_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/models/interest_state.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/screens/settings/settings_routes.dart';
import 'package:lifelog_mobile/widgets/app_page_header.dart';
import 'package:lifelog_mobile/widgets/app_safe_area.dart';
import 'package:lifelog_mobile/widgets/app_toast.dart';

import 'interest_setting_page.dart' hide InterestBadge;
import 'widgets/interest_badge.dart';

// ✅ Glass 토글
import 'package:lifelog_mobile/widgets/glass_switch.dart';

// ✅ Chevron button (사용자 제공 코드 파일로 분리해두었다고 가정)
import 'package:lifelog_mobile/widgets/glass_chevron_button.dart';

class InsightHubPage extends StatefulWidget {
  final Palette p;
  final VoidCallback? onLogout;

  const InsightHubPage({super.key, required this.p, this.onLogout});

  @override
  State<InsightHubPage> createState() => _InsightHubPageState();
}

class _InsightHubPageState extends State<InsightHubPage> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  late final AuthApiClient _authApi;
  late final InsightApiClient _insightApi;
  late final InterestApiClient _interestApi;

  bool _loading = true;
  bool _savingEnabled = false;

  bool _enabled = false;
  List<String> _keywords = const [];

  @override
  void initState() {
    super.initState();

    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _storage,
      onUnauthorized: widget.onLogout,
    );
    _insightApi = InsightApiClient(_authApi);
    _interestApi = InterestApiClient(_authApi);

    _load();
  }

  void _showToast(String message) {
    if (!mounted) return;
    AppToast.show(context, message);
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final settings = await _insightApi.getSettings();
      final InterestState interests = await _interestApi.getInterests();

      if (!mounted) return;
      setState(() {
        _enabled = settings.enabled;
        _keywords = interests.keywords;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showToast('불러오지 못했어요');
    }
  }

  Future<void> _setEnabled(bool v) async {
    if (_savingEnabled) return;

    final prev = _enabled;

    setState(() {
      _enabled = v; // optimistic
      _savingEnabled = true;
    });

    try {
      await _insightApi.setEnabled(v);
      if (!mounted) return;
      _showToast('저장했습니다.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _enabled = prev);
      _showToast('저장에 실패했어요. 네트워크를 확인해주세요');
    } finally {
      if (!mounted) return;
      setState(() => _savingEnabled = false);
    }
  }

  Future<void> _openManage() async {
    await Navigator.of(context).push(
      buildSettingsRoute<void>(
        InterestSettingPage(p: widget.p, onLogout: widget.onLogout),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  TextStyle? _sectionTitleStyle(BuildContext context, Palette p) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
      color: p.ink,
      fontWeight: FontWeight.w600,

      letterSpacing: -0.15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: AppPageHeader(title: '', titleColor: p.ink, iconColor: p.ink),
      ),
      body: AppSafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                '인사이트',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 40),

              if (_loading)
                Text(
                  '불러오는 중…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else ...[
                // -------------------------
                // 인사이트 생성 섹션
                // -------------------------
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '인사이트 생성',
                        style: _sectionTitleStyle(context, p),
                      ),
                    ),
                    AbsorbPointer(
                      absorbing: _savingEnabled,
                      child: GlassSwitch(
                        value: _enabled,
                        onChanged: _setEnabled,
                        color: p.accent,
                        enabled: !_savingEnabled,
                        blurEnabled: false,
                        outerPadding: const EdgeInsets.only(
                          right: 10,
                        ), // <- 우측 여백을 주면 화면에서 왼쪽으로 당겨짐
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _enabled
                      ? '관심사 키워드가 있어야 인사이트가 생성돼요.'
                      : '끄면 기록만 하고 인사이트는 생성하지 않아요.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.05,
                  ),
                ),
                const SizedBox(height: 40),

                // -------------------------
                // 관심사 섹션
                // -------------------------
                Row(
                  children: [
                    Expanded(
                      child: Text('관심사', style: _sectionTitleStyle(context, p)),
                    ),

                    // ✅ "편집" 텍스트 대신 ChevronButton
                    GlassChevronButton(
                      onTap: _openManage,
                      accent: p.accent,
                      depth: 0.42,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_keywords.isEmpty)
                  Text(
                    '아직 등록된 관심사가 없어요.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: p.muted,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      letterSpacing: -0.05,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final k in _keywords) InterestBadge(p: p, text: k),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

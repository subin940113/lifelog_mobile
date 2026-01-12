import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/push_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/app_page_header.dart';
import 'package:lifelog_mobile/widgets/app_safe_area.dart';
import 'package:lifelog_mobile/widgets/glass_switch.dart';
import 'package:lifelog_mobile/widgets/app_toast.dart';

class NotificationSettingPage extends StatefulWidget {
  final Palette p;
  final VoidCallback? onLogout;

  const NotificationSettingPage({super.key, required this.p, this.onLogout});

  @override
  State<NotificationSettingPage> createState() =>
      _NotificationSettingPageState();
}

class _NotificationSettingPageState extends State<NotificationSettingPage> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // 캐시 키(UX용). 서버가 최종 진실.
  static const String _kPushEnabledKey = 'push_enabled';

  late final AuthApiClient _authApi;
  late final PushApiClient _pushApi;

  bool _loading = true;
  bool _saving = false;
  bool _pushEnabled = false;

  @override
  void initState() {
    super.initState();

    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _storage,
      onUnauthorized: widget.onLogout,
    );
    _pushApi = PushApiClient(_authApi);

    _load();
  }

  void _toast(String msg) {
    if (!mounted) return;
    AppToast.show(context, msg);
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // 1) 로컬 캐시로 즉시 UI 반영(옵션)
    try {
      final v = await _storage.read(key: _kPushEnabledKey);
      final cached = (v ?? '').trim() == '1';
      if (mounted) setState(() => _pushEnabled = cached);
    } catch (_) {
      // ignore
    }

    // 2) 서버에서 실제 설정 로드
    try {
      final s = await _pushApi.getSettings();
      if (!mounted) return;

      setState(() {
        _pushEnabled = s.enabled;
        _loading = false;
      });

      // 캐시 갱신
      await _storage.write(key: _kPushEnabledKey, value: s.enabled ? '1' : '0');
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      //_toast('알림 설정을 불러오지 못했어요');
    }
  }

  /// TODO(FCM 연동):
  /// - enabled == true  -> 권한 요청 + 토큰 발급 + _pushApi.registerToken(...)
  /// - enabled == false -> (선택) _pushApi.deleteToken(...) 또는 서버에서 토큰 disable 처리
  Future<void> _applyFcmSideEffects(bool enabled) async {
    // 여기에 이전에 작업한 FCM 코드 연결
  }

  Future<void> _setPushEnabled(bool v) async {
    if (_saving) return;

    final prev = _pushEnabled;

    setState(() {
      _pushEnabled = v; // optimistic
      _saving = true;
    });

    try {
      // 1) 서버 저장 (source of truth)
      final saved = await _pushApi.setEnabled(v);

      // 2) FCM 처리(추후 연결)
      await _applyFcmSideEffects(saved.enabled);

      // 3) 캐시 갱신
      await _storage.write(
        key: _kPushEnabledKey,
        value: saved.enabled ? '1' : '0',
      );

      if (!mounted) return;
      setState(() => _pushEnabled = saved.enabled);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pushEnabled = prev);
      //_toast('저장에 실패했어요');
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  TextStyle? _sectionTitleStyle(BuildContext context, Palette p) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
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
                '알림',
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '푸시 알림',
                        style: _sectionTitleStyle(context, p),
                      ),
                    ),
                    AbsorbPointer(
                      absorbing: _saving,
                      child: GlassSwitch(
                        value: _pushEnabled,
                        onChanged: _setPushEnabled,
                        color: p.accent,
                        enabled: !_saving,
                        blurEnabled: false,
                        outerPadding: const EdgeInsets.only(right: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  _pushEnabled
                      ? '기록하기 좋은 순간을 놓치지 않도록 알려드려요.'
                      : '기록 알림을 받지 않아요.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.05,
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

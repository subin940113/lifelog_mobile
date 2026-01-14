import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/push/push_token_manager.dart';
import 'package:lifelog_mobile/theme/palette.dart';

import '../screens/auth/login_page.dart';
import '../screens/home/main_page.dart';

import 'package:lifelog_mobile/push/push_intent.dart';
import 'package:lifelog_mobile/screens/record/record_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  bool _loggedIn = false;
  bool _bootstrapped = false;
  bool _handlingPushIntent = false;

  late final AuthApiClient _authApi;
  late final PushTokenManager _pushManager;

  @override
  void initState() {
    super.initState();

    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _storage,
      onUnauthorized: _forceLogout,
    );

    _pushManager = PushTokenManager(storage: _storage, authApi: _authApi);

    // ✅ push intent가 새로 세팅되면 즉시 처리 시도
    PushIntentHolder.onChanged = () {
      // setState는 필요 없음: 네비게이션만 하면 됨
      _handlePendingPushIntentIfAny();
    };

    _restoreLogin();
  }

  @override
  void dispose() {
    // ✅ 다른 화면/리빌드에서 참조가 남지 않도록 해제
    if (PushIntentHolder.onChanged != null) {
      PushIntentHolder.onChanged = null;
    }
    super.dispose();
  }

  Future<void> _restoreLogin() async {
    final accessToken = await _storage.read(key: 'accessToken');

    if (!mounted) return;

    if (accessToken != null && accessToken.trim().isNotEmpty) {
      setState(() {
        _loggedIn = true;
        _bootstrapped = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _pushManager.registerIfPossible();
        await _handlePendingPushIntentIfAny();
      });
    } else {
      setState(() {
        _loggedIn = false;
        _bootstrapped = true;
      });
    }
  }

  Future<void> _onLoggedIn() async {
    if (!mounted) return;
    setState(() => _loggedIn = true);

    await _pushManager.registerIfPossible();
    await _handlePendingPushIntentIfAny();
  }

  Future<void> _onLogout() async {
    await _pushManager.unregisterIfPossible();

    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'accountName');
    await _storage.delete(key: 'isNewUser');

    if (!mounted) return;

    setState(() => _loggedIn = false);

    try {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {}
  }

  void _forceLogout() {
    _onLogout();
  }

  Future<void> _handlePendingPushIntentIfAny() async {
    if (!_loggedIn) return;
    if (_handlingPushIntent) return;

    final intent = PushIntentHolder.consume();
    if (intent == null) return;
    if (!mounted) return;

    if (intent.type != PushIntentType.recordPrompt) return;

    _handlingPushIntent = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RecordScreen(onLogout: _onLogout)),
      );
    } finally {
      _handlingPushIntent = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);
    final bg = p.bg;

    if (!_bootstrapped) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text(
            '불러오는 중…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: p.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // ✅ build에서 매번 addPostFrameCallback 돌리는 건 제거해도 됨 (onChanged가 트리거 역할)
    // 필요하면 유지해도 되지만, 지금은 중복 트리거가 될 수 있어서 제거 추천.

    return _loggedIn
        ? MainPage(bg: bg, p: p, onLogout: _onLogout)
        : LoginPage(bg: bg, p: p, onLoggedIn: _onLoggedIn);
  }
}

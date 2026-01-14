import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/push/push_token_manager.dart';
import 'package:lifelog_mobile/theme/palette.dart';

import '../screens/auth/login_page.dart';
import '../screens/home/main_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  bool _loggedIn = false;
  bool _bootstrapped = false;

  late final AuthApiClient _authApi;
  late final PushTokenManager _pushManager;

  @override
  void initState() {
    super.initState();

    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _storage,
      // 토큰이 없거나 갱신 실패 등으로 401/403이 반복되면 여기로 수렴
      onUnauthorized: _forceLogout,
    );

    _pushManager = PushTokenManager(
      storage: _storage,
      authApi: _authApi,
    );

    _restoreLogin();
  }

  Future<void> _restoreLogin() async {
    // 앱 재실행 시 secure storage에 accessToken이 있으면 자동 로그인 복원
    final accessToken = await _storage.read(key: 'accessToken');

    if (!mounted) return;

    if (accessToken != null && accessToken.trim().isNotEmpty) {
      setState(() {
        _loggedIn = true;
        _bootstrapped = true;
      });

      // 로그인 복원 직후: 서버에 토큰 업서트(가능하면)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _pushManager.registerIfPossible();
      });
    } else {
      setState(() {
        _loggedIn = false;
        _bootstrapped = true;
      });
    }
  }

  /// LoginPage에서 로그인 성공 시 호출
  Future<void> _onLoggedIn() async {
    if (!mounted) return;
    setState(() => _loggedIn = true);

    // 로그인 직후: 서버에 토큰 업서트
    await _pushManager.registerIfPossible();
  }

  /// 앱 전역 로그아웃(모든 화면은 여기로만 빠지게)
  Future<void> _onLogout() async {
    // 1) 서버에서 토큰 제거 시도(실패해도 로컬 로그아웃은 진행)
    await _pushManager.unregisterIfPossible();

    // 2) 로컬 토큰 정리
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'accountName');
    await _storage.delete(key: 'isNewUser');

    if (!mounted) return;

    // 3) UI를 로그인 상태로 전환
    setState(() => _loggedIn = false);

    // 4) 네비게이션 스택 정리(가능하면 루트로)
    try {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      // navigator가 아직 준비 전이면 무시
    }
  }

  /// AuthApiClient의 onUnauthorized에서 호출되는 강제 로그아웃
  void _forceLogout() {
    // 비동기 정리 로직은 동일하게 사용
    _onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);
    final bg = p.bg;

    // 부팅 중(secure storage 확인 전)에는 화면 깜빡임 방지
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

    return _loggedIn
        ? MainPage(bg: bg, p: p, onLogout: _onLogout)
        : LoginPage(bg: bg, p: p, onLoggedIn: _onLoggedIn);
  }
}

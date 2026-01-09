// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/brand_logo.dart';

import 'models/provider_key.dart';
import 'widgets/accent_gradient_text.dart';
import 'widgets/inline_bubble_label.dart';

class LoginPage extends StatefulWidget {
  final Color? bg;
  final Palette? p;
  final VoidCallback onLoggedIn;

  const LoginPage({super.key, this.bg, this.p, required this.onLoggedIn});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _ctaPressed = false;
  ProviderKey? _pressedKey;
  String? _error;

  ProviderKey? _recentProvider;

  late final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final AnimationController _glassSheen;

  static const _kLastLoginProviderKey = 'last_login_provider';

  @override
  void initState() {
    super.initState();

    final webClientId = ApiConfig.googleWebClientId.trim();
    _googleSignIn = GoogleSignIn(
      scopes: const <String>['email'],
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );

    _glassSheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _loadRecentProvider();
  }

  Future<void> _loadRecentProvider() async {
    try {
      final raw = await _secureStorage.read(key: _kLastLoginProviderKey);
      if (!mounted) return;
      setState(() {
        _recentProvider = ProviderKeyX.fromStorage(raw);
      });
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _glassSheen.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google idToken을 가져오지 못했습니다.');
      }

      final client = AuthApiClient(
        baseUrl: ApiConfig.baseUrl,
        storage: _secureStorage,
        onUnauthorized: () {
          _secureStorage.deleteAll();
        },
      );

      final authResult = await client.loginWithGoogleIdToken(idToken);

      await _secureStorage.write(key: 'accessToken', value: authResult.accessToken);
      await _secureStorage.write(key: 'refreshToken', value: authResult.refreshToken);
      await _secureStorage.write(key: 'accountName', value: authResult.displayName);
      await _secureStorage.write(key: 'isNewUser', value: authResult.isNewUser.toString());

      await _secureStorage.write(
        key: _kLastLoginProviderKey,
        value: ProviderKey.google.storageValue,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _recentProvider = ProviderKey.google;
      });
      widget.onLoggedIn();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '로그인에 실패했습니다.\n${e.toString()}';
      });
    }
  }

  Future<void> _loginWithKakao() async {
    if (!mounted) return;
    setState(() => _error = '카카오 로그인은 준비 중입니다.');
  }

  Future<void> _loginWithNaver() async {
    if (!mounted) return;
    setState(() => _error = '네이버 로그인은 준비 중입니다.');
  }

  double _bubbleOffsetXForProvider(ProviderKey? provider) {
    const step = 80.0; // icon(64) + gap(16) 기준
    switch (provider) {
      case ProviderKey.kakao:
        return -step;
      case ProviderKey.naver:
        return 0.0;
      case ProviderKey.google:
        return step;
      default:
        return 0.0;
    }
  }

  void _setPressed(ProviderKey? key, bool v) {
    if (_loading) return;
    setState(() {
      _ctaPressed = v;
      _pressedKey = v ? key : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p ?? Palette.from(Theme.of(context).colorScheme);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = widget.bg ?? (isDark ? p.bg : const Color(0xFFFAFAFA));
    final copyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.35,
          fontSize: 16,
          letterSpacing: -1,
        );

    final panelHeight = MediaQuery.sizeOf(context).height * 0.3;

    final hasRecent = _recentProvider != null;
    final bubbleText = hasRecent ? '최근 로그인' : 'SNS 계정으로 이어가기';
    final bubbleX = hasRecent ? _bubbleOffsetXForProvider(_recentProvider) : 0.0;

    // 말풍선 위 마진/아이콘 Y 고정 관련
    const bubbleSlotHeight = 46.0;
    const bubbleToIconsGap = 10.0;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 120),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BrandLogo(
                            p: p,
                            style: BrandLogoStyle.wordmark,
                            scale: 1.6,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AccentGradientText(
                                text: '흘러가는 생각이 사라지기 전에',
                                style: copyStyle?.copyWith(
                                  fontSize: (copyStyle?.fontSize ?? 16) + 2,
                                  fontWeight: FontWeight.w500,
                                ),
                                accent: p.accent,
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(width: 2),
                              Transform.translate(
                                offset: const Offset(0, 1),
                                child: Text(
                                  '.',
                                  style: copyStyle?.copyWith(
                                    color: Color.lerp(p.accent, Colors.black, 0.25),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: panelHeight,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(26),
                      topRight: Radius.circular(26),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(p.accent, Colors.white, 0.10)!,
                        p.accent,
                        Color.lerp(p.accent, Colors.black, 0.12)!,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.28 : 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _glassSheen,
                            builder: (context, _) {
                              final w = MediaQuery.sizeOf(context).width;
                              final x = (-w * 0.8) + (w * 1.6 * _glassSheen.value);
                              return Opacity(
                                opacity: isDark ? 0.12 : 0.10,
                                child: Transform.translate(
                                  offset: Offset(x, 0),
                                  child: Transform.rotate(
                                    angle: -0.22,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: w * 0.38,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withOpacity(0.18),
                                              Colors.white.withOpacity(0.32),
                                              Colors.white.withOpacity(0.18),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Stack(
                          children: [
                            Align(
                              alignment: const Alignment(0.0, -0.9),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_error != null) ...[
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withOpacity(0.92),
                                            fontWeight: FontWeight.w600,
                                            height: 1.35,
                                          ),
                                    ),
                                  ],

                                  SizedBox(
                                    height: bubbleSlotHeight,
                                    child: Center(
                                      child: Transform.translate(
                                        offset: Offset(bubbleX, 0),
                                        child: InlineBubbleLabel(text: bubbleText),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: bubbleToIconsGap),

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      _IconButton(
                                        iconAsset: 'assets/icons/signin_with_kakao.png',
                                        enabled: !_loading,
                                        pressed: _ctaPressed && _pressedKey == ProviderKey.kakao,
                                        onPressedStateChanged: (v) => _setPressed(ProviderKey.kakao, v),
                                        onTap: _loading ? null : _loginWithKakao,
                                      ),
                                      const SizedBox(width: 16),
                                      _IconButton(
                                        iconAsset: 'assets/icons/signin_with_naver.png',
                                        enabled: !_loading,
                                        pressed: _ctaPressed && _pressedKey == ProviderKey.naver,
                                        onPressedStateChanged: (v) => _setPressed(ProviderKey.naver, v),
                                        onTap: _loading ? null : _loginWithNaver,
                                      ),
                                      const SizedBox(width: 16),
                                      _IconButton(
                                        iconAsset: 'assets/icons/signin_with_google.png',
                                        enabled: !_loading,
                                        pressed: _ctaPressed && _pressedKey == ProviderKey.google,
                                        onPressedStateChanged: (v) => _setPressed(ProviderKey.google, v),
                                        onTap: _loading ? null : _loginWithGoogle,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Text(
                                  '© ${DateTime.now().year} bluelog. All rights reserved.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.82),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.1,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 페이지 내부에서만 쓰는 “아이콘 표시 + 눌림 피드백”
/// (파일 분리는 최소화하면서도, 위젯 책임은 작게 유지)
class _IconButton extends StatelessWidget {
  final String iconAsset;
  final bool enabled;
  final bool pressed;
  final ValueChanged<bool> onPressedStateChanged;
  final VoidCallback? onTap;

  const _IconButton({
    required this.iconAsset,
    required this.enabled,
    required this.pressed,
    required this.onPressedStateChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (!enabled || onTap == null) return;
        onPressedStateChanged(true);
      },
      onTapUp: (_) {
        if (!enabled || onTap == null) return;
        onPressedStateChanged(false);
      },
      onTapCancel: () {
        if (!enabled || onTap == null) return;
        onPressedStateChanged(false);
      },
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: !enabled ? 0.55 : (pressed ? 0.55 : 1.0),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: Image.asset(
              iconAsset,
              width: 57,
              height: 57,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
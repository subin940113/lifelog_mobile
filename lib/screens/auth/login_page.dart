// lib/screens/auth/login_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/main_signal_blob.dart';

import 'models/provider_key.dart';

class LoginPage extends StatefulWidget {
  final Color? bg;
  final Palette? p;
  final VoidCallback onLoggedIn;

  const LoginPage({super.key, this.bg, this.p, required this.onLoggedIn});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  ProviderKey? _recentProvider;

  late final AnimationController _arrowController;
  late final Animation<double> _arrowDy;

  late final AnimationController _blobController;

  late final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _kLastLoginProviderKey = 'last_login_provider';

  @override
  void initState() {
    super.initState();

    final webClientId = ApiConfig.googleWebClientId.trim();
    _googleSignIn = GoogleSignIn(
      scopes: const <String>['email'],
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );

    _loadRecentProvider();

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _arrowDy = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _arrowController.repeat(reverse: true);

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _blobController.dispose();
    super.dispose();
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

  Future<AuthApiClient> _client() async {
    return AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _secureStorage,
      onUnauthorized: () {
        _secureStorage.deleteAll();
      },
    );
  }

  Future<void> _persistLogin(
    AuthLoginResult authResult,
    ProviderKey provider,
  ) async {
    await _secureStorage.write(key: 'accessToken', value: authResult.accessToken);
    await _secureStorage.write(key: 'refreshToken', value: authResult.refreshToken);
    await _secureStorage.write(key: 'accountName', value: authResult.displayName);
    await _secureStorage.write(key: 'isNewUser', value: authResult.isNewUser.toString());
    await _secureStorage.write(key: _kLastLoginProviderKey, value: provider.storageValue);
  }

  void _handleLoginError(String userMessage, Object error, [StackTrace? st]) {
    debugPrint('[LOGIN] $userMessage');
    debugPrint('[LOGIN] error: $error');
    if (st != null) debugPrint(st.toString());

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = userMessage;
    });
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

      final client = await _client();
      final authResult = await client.loginWithGoogleIdToken(idToken);
      await _persistLogin(authResult, ProviderKey.google);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _recentProvider = ProviderKey.google;
      });
      widget.onLoggedIn();
    } catch (e, st) {
      _handleLoginError('구글 로그인에 문제가 발생했습니다. 다시 시도해주세요.', e, st);
    }
  }

  Future<void> _loginWithKakao() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      kakao.OAuthToken token;

      final installed = await kakao.isKakaoTalkInstalled();
      if (installed) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (_) {
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final accessToken = token.accessToken;
      if (accessToken.isEmpty) {
        throw Exception('Kakao accessToken이 비어있습니다.');
      }

      final client = await _client();
      final authResult = await client.loginWithKakaoAccessToken(accessToken);
      await _persistLogin(authResult, ProviderKey.kakao);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _recentProvider = ProviderKey.kakao;
      });
      widget.onLoggedIn();
    } catch (e, st) {
      _handleLoginError('카카오 로그인에 문제가 발생했습니다. 다시 시도해주세요.', e, st);
    }
  }

  Future<void> _loginWithNaver() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await FlutterNaverLogin.logIn();
      debugPrint('[NAVER] status: ${result.status}');

      final statusStr = result.status.toString();
      final isLoggedIn = statusStr.endsWith('.loggedIn');
      final isLoggedOut = statusStr.endsWith('.loggedOut');

      if (isLoggedIn) {
        // continue
      } else if (isLoggedOut) {
        throw Exception('NAVER_LOGIN_STATUS_LOGGED_OUT');
      } else {
        throw Exception('NAVER_LOGIN_STATUS_ERROR');
      }

      final token = await FlutterNaverLogin.getCurrentAccessToken();
      if (!token.isValid()) {
        throw Exception('NAVER_ACCESS_TOKEN_INVALID');
      }

      final accessToken = token.accessToken.trim();
      if (accessToken.isEmpty) {
        throw Exception('NAVER_ACCESS_TOKEN_EMPTY');
      }

      final client = await _client();
      final authResult = await client.loginWithNaverAccessToken(accessToken);
      await _persistLogin(authResult, ProviderKey.naver);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _recentProvider = ProviderKey.naver;
      });
      widget.onLoggedIn();
    } catch (e, st) {
      final msg = (e.toString().contains('NAVER_LOGIN_STATUS_'))
          ? '네이버 로그인이 취소되었거나 완료되지 않았습니다.'
          : '네이버 로그인에 문제가 발생했습니다. 다시 시도해주세요.';
      _handleLoginError(msg, e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white;

    // 라이트 톤 유지
    final stroke = Palette.strokeLight;

    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final screenH = media.size.height;
    final shortest = math.min(screenW, screenH);

    // -----------------------------
    // Responsive scale tokens
    // -----------------------------
    final sidePad = (shortest * 0.055).clamp(16.0, 26.0);
    final bottomSafePad = (shortest * 0.020).clamp(6.0, 14.0);

    // 브랜드 블록 top padding
    final brandTopPad = (screenH * 0.085).clamp(48.0, 120.0);

    // ✅ Blob size: 더 크게 (chevron 대비 존재감 강화)
    // - shortest 기준 0.60로 상향
    // - max도 조금 올림
    final blobSize = (shortest * 0.68).clamp(260.0, 440.0);
    
    // Chevron size (slightly increased to balance larger blob)
    final chevronSize = (shortest * 0.076).clamp(28.0, 50.0);

    // Social buttons sizing
    final btnH = (shortest * 0.115).clamp(50.0, 66.0);
    final btnGap = (shortest * 0.022).clamp(8.0, 14.0);
    const int btnCount = 3;

    // Button corner radius: slightly less rounded on small devices
    final btnRadius = (shortest * 0.032).clamp(10.0, 16.0);
    final iconBox = (shortest * 0.060).clamp(18.0, 24.0);
    final iconSize = (shortest * 0.058).clamp(18.0, 24.0);
    // Social button label: slightly smaller than before
    final labelFontSize = (shortest * 0.043).clamp(13.5, 17.5);
    final double labelSpacing = -0.2; // restore tighter letter spacing

    final footerFontSize = (shortest * 0.030).clamp(10.5, 12.5);

    final buttonsH = (btnH * btnCount) + (btnGap * (btnCount - 1));
    final chevronH = chevronSize;

    return Theme(
      data: ThemeData.light().copyWith(
        // keep typography consistent with the app while forcing light colors
        textTheme: Theme.of(context).textTheme,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(sidePad, 0, sidePad, bottomSafePad),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand block (top-center)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: brandTopPad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: (shortest * 0.050).clamp(14.0, 44.0)),
                              SizedBox(
                                width: blobSize,
                                height: blobSize,
                                child: AnimatedBuilder(
                                  animation: _blobController,
                                  builder: (context, _) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        MainSignalBlob(
                                          t: _blobController.value,
                                          size: blobSize,
                                          hasSignal: false,
                                        ),
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: FloatingWordInBlob(
                                              t: _blobController.value,
                                              word: 'bluegol',
                                              color: stroke,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Middle area
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, midCs) {
                            final midH = midCs.maxHeight;

                            // 아래로부터 10% 올리기 (요구 유지) + clamp
                            final bottomLift = (midH * 0.10).clamp(12.0, 120.0);

                            final buttonsTopY =
                                (midH - bottomLift - buttonsH).clamp(0.0, midH);
                            final availableForChevron = buttonsTopY;

                            final chevronTop = ((availableForChevron - chevronH) / 2.0)
                                .clamp(0.0, math.max(0.0, availableForChevron - chevronH))
                                .toDouble();

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Chevron (independent)
                                Positioned(
                                  top: chevronTop,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: AnimatedBuilder(
                                      animation: _arrowDy,
                                      builder: (context, child) {
                                        final floatAmp = (shortest * 0.016).clamp(6.0, 12.0);
                                        final dy = (_arrowDy.value / 10.0) * floatAmp;
                                        return Transform.translate(
                                          offset: Offset(0, dy),
                                          child: child,
                                        );
                                      },
                                      child: Image.asset(
                                        'assets/icons/chevron_light.png',
                                        width: chevronSize,
                                        height: chevronSize,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),

                                // ✅ Buttons block: 이전처럼 "가로로 퍼지게"
                                // - ConstrainedBox/MaxWidth 제거
                                // - Column이 stretch로 가고, 각 버튼 width: double.infinity로 전체 폭 사용
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: bottomLift),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _SocialLoginButton(
                                          height: btnH,
                                          radius: btnRadius,
                                          iconBox: iconBox,
                                          iconSize: iconSize,
                                          labelFontSize: labelFontSize,
                                          labelLetterSpacing: labelSpacing,
                                          label: '카카오로 시작하기',
                                          iconAsset: 'assets/icons/kakao_logo.png',
                                          enabled: !_loading,
                                          background: const Color(0xFFFEE500),
                                          foreground: const Color(0xFF191600),
                                          onTap: _loading ? null : _loginWithKakao,
                                          badgeText: _recentProvider == ProviderKey.kakao ? '최근' : null,
                                        ),
                                        SizedBox(height: btnGap),
                                        _SocialLoginButton(
                                          height: btnH,
                                          radius: btnRadius,
                                          iconBox: iconBox,
                                          iconSize: iconSize * 0.92,
                                          labelFontSize: labelFontSize,
                                          labelLetterSpacing: labelSpacing,
                                          label: '네이버로 시작하기',
                                          iconAsset: 'assets/icons/naver_logo.png',
                                          enabled: !_loading,
                                          background: const Color(0xFF03A94D),
                                          foreground: Colors.white,
                                          onTap: _loading ? null : _loginWithNaver,
                                          badgeText: _recentProvider == ProviderKey.naver ? '최근' : null,
                                        ),
                                        SizedBox(height: btnGap),
                                        _SocialLoginButton(
                                          height: btnH,
                                          radius: btnRadius,
                                          iconBox: iconBox,
                                          iconSize: iconSize,
                                          labelFontSize: labelFontSize,
                                          labelLetterSpacing: labelSpacing,
                                          label: '구글로 시작하기',
                                          iconAsset: 'assets/icons/google_logo.png',
                                          enabled: !_loading,
                                          background: Colors.white,
                                          foreground: const Color(0xFF1A1A1A),
                                          onTap: _loading ? null : _loginWithGoogle,
                                          badgeText: _recentProvider == ProviderKey.google ? '최근' : null,
                                          iconNudgeX: 0,
                                        ),
                                        if (_error != null) ...[
                                          SizedBox(height: (shortest * 0.022).clamp(8.0, 14.0)),
                                          Text(
                                            _error!,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.redAccent.withOpacity(0.85),
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.25,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Footer pinned
                      Padding(
                        padding: EdgeInsets.only(bottom: (shortest * 0.004).clamp(0.0, 6.0)),
                        child: Text(
                          '© ${DateTime.now().year} bluelog. All rights reserved.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: stroke.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'MontserratAlternates',
                                fontSize: footerFontSize,
                              ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool enabled;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  final double height;
  final double radius;
  final double iconBox;
  final double iconSize;
  final double labelFontSize;
  final double labelLetterSpacing;

  final String? badgeText;
  final double iconNudgeX;

  const _SocialLoginButton({
    required this.label,
    required this.iconAsset,
    required this.enabled,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.height,
    required this.radius,
    required this.iconBox,
    required this.iconSize,
    required this.labelFontSize,
    required this.labelLetterSpacing,
    this.badgeText,
    this.iconNudgeX = 0,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    final media = MediaQuery.of(context);
    final shortest = math.min(media.size.width, media.size.height);
    final blur1 = (shortest * 0.030).clamp(10.0, 18.0);
    final blur2 = (shortest * 0.050).clamp(18.0, 28.0);
    final offset1 = (shortest * 0.012).clamp(4.0, 8.0);
    final offset2 = (shortest * 0.020).clamp(8.0, 14.0);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: enabled ? 1.0 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: blur1,
              offset: Offset(0, offset1),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: blur2,
              offset: Offset(0, offset2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: br,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: br,
            child: Ink(
              height: height,
              width: double.infinity, // ✅ 가로로 퍼짐
              decoration: BoxDecoration(
                color: background,
                borderRadius: br,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (shortest * 0.040).clamp(14.0, 18.0),
                  vertical: (shortest * 0.010).clamp(3.0, 6.0),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: iconBox,
                          height: iconBox,
                          child: Center(
                            child: Transform.translate(
                              offset: Offset(iconNudgeX, 0),
                              child: Image.asset(
                                iconAsset,
                                width: iconSize,
                                height: iconSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: (shortest * 0.026).clamp(8.0, 12.0)),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                            fontSize: labelFontSize,
                            letterSpacing: labelLetterSpacing,
                          ),
                        ),
                      ],
                    ),
                    if (badgeText != null)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: (shortest * 0.022).clamp(7.0, 10.0),
                            vertical: (shortest * 0.012).clamp(3.0, 5.0),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              color: foreground.withOpacity(0.78),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                              fontSize: (shortest * 0.030).clamp(10.0, 12.0),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
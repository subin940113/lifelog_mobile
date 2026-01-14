import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ✅ Kakao / Naver
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/brand_logo.dart';

import 'models/provider_key.dart';
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
  String? _error;
  ProviderKey? _recentProvider;

  late final AnimationController _arrowController;
  late final Animation<double> _arrowDy;

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
  }

  @override
  void dispose() {
    _arrowController.dispose();
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
    await _secureStorage.write(
      key: 'accessToken',
      value: authResult.accessToken,
    );
    await _secureStorage.write(
      key: 'refreshToken',
      value: authResult.refreshToken,
    );
    await _secureStorage.write(
      key: 'accountName',
      value: authResult.displayName,
    );
    await _secureStorage.write(
      key: 'isNewUser',
      value: authResult.isNewUser.toString(),
    );

    await _secureStorage.write(
      key: _kLastLoginProviderKey,
      value: provider.storageValue,
    );
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
    final p = widget.p ?? Palette.from(Theme.of(context).colorScheme);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = Colors.white;

    final copyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.35,
      fontSize: 16,
      letterSpacing: -0.8,
    );

    final hasRecent = _recentProvider != null;
    final bubbleText = hasRecent ? '최근 로그인' : 'SNS 계정으로 이어가기';

    final w = MediaQuery.sizeOf(context).width;
    // ✅ “가로 꽉 차지 않게” + “우측 정렬”을 위한 최대 폭 (수정됨)
    final buttonMaxWidth = (w * 0.62).clamp(240.0, 320.0);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;

                  // ✅ 여기 값만 바꾸면 "아래에서 몇 % 올라오게" 조절 가능
                  final ctaBottom = h * 0.10; // 소셜 로그인 블록: 아래에서 10% 위
                  final footerBottom = 0.0; // 맨 아래 문구: SafeArea 하단에 최대한 붙임

                  return Stack(
                    children: [
                      // ✅ Brand block (top-center)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 90),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  SizedBox(
                                    width: 240,
                                    height: 240,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icons/brand_logo.png',
                                          width: 240,
                                          height: 240,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                        // ✅ 우하단 원 가장자리를 따라 "bluelog" (B안: 실제 원호 텍스트)
                                        IgnorePointer(
                                          child: CustomPaint(
                                            size: const Size(240, 240),
                                            painter: _ArcTextPainter(
                                              text: 'bluelog',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: -0.9,
                                                color: const Color(
                                                  0xFF5FAFE8,
                                                ).withOpacity(0.55),
                                              ),
                                              // 이미지에 투명 패딩이 있어도 "원 위"에 보이도록 살짝 위로 보정
                                              centerYOffset: -8,
                                              centerXOffset: 6,
                                              // 240 기준: 원 밖으로 내려가지 않게 충분히 안쪽으로
                                              radius: 100,
                                              // 우하단(4~5시) 쪽에서 오른쪽으로 읽히게: 시작 각을 끝점으로 두고, sweep를 음수로
                                              startAngle: 1.23,
                                              // 글자 길이에 맞춘 원호 폭 (방향 반전)
                                              sweepAngle: -0.65,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ✅ Social login CTA block (positioned by % from bottom)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: ctaBottom,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            AnimatedBuilder(
                              animation: _arrowDy,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _arrowDy.value),
                                  child: child,
                                );
                              },
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const RadialGradient(
                                    center: Alignment(0.55, -0.65), // 우상단 하이라이트
                                    radius: 1.25,
                                    colors: [
                                      Color(0xFFCFEFFF),
                                      Color(0xFF8FD3F7),
                                      Color(0xFF5FAFE8),
                                      Color(0xFF4A9FE0),
                                    ],
                                    stops: [0.0, 0.35, 0.70, 1.0],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.srcIn,
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            _SocialLoginButton(
                              label: '카카오로 시작하기',
                              iconAsset: 'assets/icons/kakao_logo.png',
                              enabled: !_loading,
                              background: const Color(0xFFFEE500),
                              foreground: const Color(0xFF191600),
                              onTap: _loading ? null : _loginWithKakao,
                              badgeText: _recentProvider == ProviderKey.kakao
                                  ? '최근'
                                  : null,
                            ),
                            const SizedBox(height: 10),

                            _SocialLoginButton(
                              label: '네이버로 시작하기',
                              iconAsset: 'assets/icons/naver_logo.png',
                              enabled: !_loading,
                              background: const Color(0xFF03A94D),
                              foreground: Colors.white,
                              onTap: _loading ? null : _loginWithNaver,
                              badgeText: _recentProvider == ProviderKey.naver
                                  ? '최근'
                                  : null,
                            ),
                            const SizedBox(height: 10),

                            _SocialLoginButton(
                              label: '구글로 시작하기',
                              iconAsset: 'assets/icons/google_logo.png',
                              enabled: !_loading,
                              background: Colors.white,
                              foreground: const Color(0xFF1A1A1A),
                              onTap: _loading ? null : _loginWithGoogle,
                              badgeText: _recentProvider == ProviderKey.google
                                  ? '최근'
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      // ✅ Footer (positioned by % from bottom)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: footerBottom,
                        child: Text(
                          '© ${DateTime.now().year} bluelog. All rights reserved.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 11,
                                color: const Color(0xFF5FAFE8).withOpacity(0.7),
                                fontWeight: FontWeight.w500,
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

  /// 최근 로그인 배지 (ex: '최근'), 없으면 null
  final String? badgeText;

  /// 로고 PNG 여백 보정을 위한 X축 미세 이동 (Google용)
  final double iconNudgeX;

  const _SocialLoginButton({
    required this.label,
    required this.iconAsset,
    required this.enabled,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.badgeText,
    this.iconNudgeX = 0,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: enabled ? 1.0 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            // 메인 소프트 그림자 (강도 감소)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.14 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            // 하단 퍼짐 그림자 (존재감만 유지)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.08 : 0.03),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: radius,
            child: Ink(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: background,
                borderRadius: radius,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    /// ✅ 중앙 컨텐츠 (배지와 완전히 분리)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Center(
                            child: Transform.translate(
                              offset: Offset(iconNudgeX, 0),
                              child: Image.asset(
                                iconAsset,
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ],
                    ),

                    /// ✅ 최근 로그인 배지 (레이아웃에 영향 없음)
                    if (badgeText != null)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                              isDark ? 0.20 : 0.06,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeText!,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: foreground.withOpacity(
                                    isDark ? 0.92 : 0.78,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
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

class _ArcTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double radius;
  final double startAngle; // radians (0=right, pi/2=down)
  final double sweepAngle; // radians
  final double centerYOffset;
  final double centerXOffset;

  _ArcTextPainter({
    required this.text,
    required this.style,
    required this.radius,
    required this.startAngle,
    required this.sweepAngle,
    this.centerYOffset = 0,
    this.centerXOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2 + centerXOffset,
      size.height / 2 + centerYOffset,
    );

    // Measure each glyph width so spacing feels natural on the arc.
    final glyphPainters = <TextPainter>[];
    final glyphWidths = <double>[];
    double totalWidth = 0;

    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      final tp = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      glyphPainters.add(tp);
      glyphWidths.add(tp.width);
      totalWidth += tp.width;
    }

    double angle = startAngle;

    for (int i = 0; i < glyphPainters.length; i++) {
      final w = glyphWidths[i];
      final portion = (totalWidth == 0) ? 0 : (w / totalWidth);
      final delta = sweepAngle * portion;

      final mid = angle + delta / 2;

      final pos = Offset(
        center.dx + radius * math.cos(mid),
        center.dy + radius * math.sin(mid),
      );

      canvas.save();
      canvas.translate(pos.dx, pos.dy);

      // Tangent rotation so glyphs follow the circle.
      // If the glyph would be upside down (on the lower half), flip by π to keep it readable.
      var rot = mid + math.pi / 2;

      // Normalize to [0, 2π)
      rot = rot % (2 * math.pi);

      // When the tangent points left (i.e., upside-down text), flip.
      if (rot > math.pi / 2 && rot < 3 * math.pi / 2) {
        rot += math.pi;
      }

      canvas.rotate(rot);

      final tp = glyphPainters[i];
      final ch = text[i];

      // 글자별 미세 보정: g는 위로, b는 아래로
      double nudgeY = 0.0;
      if (ch == 'g') {
        nudgeY = -1.5;
      } else if (ch == 'b') {
        nudgeY = 1.5;
      } else if (ch == 'l') {
        nudgeY = 1.2;
      } else if (ch == 'u') {
        nudgeY = 1.2;
      } else if (ch == 'e') {
        nudgeY = 1.35;
      }

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2 + nudgeY));

      canvas.restore();
      // 'e' 뒤에만 살짝 간격을 추가 (우측 여백)
      final extraAfter = (ch == 'e')
          ? -0.015
          : 0.0; // radians, 필요시 0.02~0.05 조정
      angle += delta + extraAfter;
    }
  }

  @override
  bool shouldRepaint(covariant _ArcTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.radius != radius ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.centerYOffset != centerYOffset ||
        oldDelegate.centerXOffset != centerXOffset;
  }
}

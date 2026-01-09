import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/brand_logo.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/api/auth_api_client.dart';

class LoginPage extends StatefulWidget {
  final Color? bg;
  final Palette? p;
  final VoidCallback onLoggedIn;

  const LoginPage({super.key, this.bg, this.p, required this.onLoggedIn});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _ctaPressed = false;
  _ProviderKey? _pressedKey;
  String? _error;

  late final GoogleSignIn _googleSignIn;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  late final AnimationController _glassSheen;

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

      if (!mounted) return;
      setState(() => _loading = false);
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
    // TODO: Kakao OAuth 연동
    if (!mounted) return;
    setState(() {
      _error = '카카오 로그인은 준비 중입니다.';
    });
  }

  Future<void> _loginWithNaver() async {
    // TODO: Naver OAuth 연동
    if (!mounted) return;
    setState(() {
      _error = '네이버 로그인은 준비 중입니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p ?? Palette.from(Theme.of(context).colorScheme);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ 배경은 기존 정책 유지
    final bg = widget.bg ?? (isDark ? p.bg : const Color(0xFFFAFAFA));

    final errorColor = isDark ? p.muted.withOpacity(0.92) : p.muted;
    final footerColor =
        isDark ? p.muted.withOpacity(0.70) : p.muted.withOpacity(0.80);

    final copyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.35,
          fontSize: 16,
          letterSpacing: -1,
        );

    final ctaFontSize = (copyStyle?.fontSize ?? 16) + 2;

    final panelHeight = MediaQuery.sizeOf(context).height * (1 / 3);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ✅ 상단 콘텐츠
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                // ✅ 상단 콘텐츠만 좌우 패딩 적용
                padding: const EdgeInsets.fromLTRB(28, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ 상단 여백 크게
                    const SizedBox(height: 90),

                    // ✅ 좌측 상단: 로고 + 카피
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

                          // ✅ 카피는 accent 색으로, 파란 점 추가
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              _AccentGradientText(
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

            // ✅ 하단: accent 컬러 배경은 화면의 하단 1/3을 채우고, 내용은 바닥에 고정
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
                      // ✅ 유리처럼 빛나는 sheen 애니메이션
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

                      // ✅ 배경은 full-bleed 유지, 내용만 inset
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Stack(
                          children: [
                            // (Chevron icon removed; now included inline with CTA text)
                            // ✅ 중앙: CTA (필요 시 에러도 중앙 블록 위쪽에)
                            Align(
                              alignment: const Alignment(0.0, -0.5),
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
                                    const SizedBox(height: 12),
                                  ],
                                  Text(
                                    'SNS 계정으로 시작하기',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.86),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                          letterSpacing: -0.4,
                                        ),
                                  ),
                                  const SizedBox(height: 13),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      _ProviderIconOnlyButton(
                                        keyId: _ProviderKey.kakao,
                                        iconAsset: 'assets/icons/signin_with_kakao.png',
                                        onTap: _loading ? null : _loginWithKakao,
                                        pressed: _ctaPressed && _pressedKey == _ProviderKey.kakao,
                                        onPressedStateChanged: (v) {
                                          if (_loading) return;
                                          setState(() {
                                            _ctaPressed = v;
                                            _pressedKey = v ? _ProviderKey.kakao : null;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      _ProviderIconOnlyButton(
                                        keyId: _ProviderKey.naver,
                                        iconAsset: 'assets/icons/signin_with_naver.png',
                                        onTap: _loading ? null : _loginWithNaver,
                                        pressed: _ctaPressed && _pressedKey == _ProviderKey.naver,
                                        onPressedStateChanged: (v) {
                                          if (_loading) return;
                                          setState(() {
                                            _ctaPressed = v;
                                            _pressedKey = v ? _ProviderKey.naver : null;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      _ProviderIconOnlyButton(
                                        keyId: _ProviderKey.google,
                                        iconAsset: 'assets/icons/signin_with_google.png',
                                        onTap: _loading ? null : _loginWithGoogle,
                                        pressed: _ctaPressed && _pressedKey == _ProviderKey.google,
                                        onPressedStateChanged: (v) {
                                          if (_loading) return;
                                          setState(() {
                                            _ctaPressed = v;
                                            _pressedKey = v ? _ProviderKey.google : null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ✅ 하단: footer는 하단 여백을 두고 살짝 위로
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 50),
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

class _AuthText extends StatefulWidget {
  final Palette p;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _AuthText({
    required this.p,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_AuthText> createState() => _AuthTextState();
}

class _AuthTextState extends State<_AuthText> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color tintWhite(Color tint, {double t = 0.10, double opacity = 0.94}) {
      final mixed = Color.lerp(Colors.white, tint, t)!;
      return mixed.withOpacity(opacity);
    }

    final enabledColor = isDark
        ? tintWhite(p.accent, t: 0.10, opacity: 0.84)
        : p.ink.withOpacity(0.97);

    final disabledColor = isDark
        ? tintWhite(p.accent, t: 0.08, opacity: 0.55)
        : p.muted;

    final color = widget.enabled ? enabledColor : disabledColor;
    final opacity = widget.enabled ? (_pressed ? 0.55 : 1.0) : 0.45;

    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: (_) {
        if (!widget.enabled) return;
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (!widget.enabled) return;
        setState(() => _pressed = false);
      },
      onTapCancel: () {
        if (!widget.enabled) return;
        setState(() => _pressed = false);
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
          ),
        ),
      ),
    );
  }
}

class _AccentGradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color accent;
  final TextAlign textAlign;

  const _AccentGradientText({
    required this.text,
    required this.style,
    required this.accent,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    // Match BrandLogo's subtle gradient tuning
    final light = Color.lerp(accent, Colors.white, 0.12)!; // 12%
    final dark = Color.lerp(accent, Colors.black, 0.10)!; // 10%

    final child = Text(
      text,
      textAlign: textAlign,
      style: style?.copyWith(color: Colors.white),
      maxLines: 1,
      overflow: TextOverflow.visible,
    );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: const Alignment(-0.7, -1.0),
          end: const Alignment(0.8, 1.0),
          colors: [light, accent, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}




enum _ProviderKey { google, kakao, naver }


class _ProviderIconOnlyButton extends StatelessWidget {
  final _ProviderKey keyId;
  final String iconAsset;
  final VoidCallback? onTap;
  final bool pressed;
  final ValueChanged<bool> onPressedStateChanged;

  const _ProviderIconOnlyButton({
    required this.keyId,
    required this.iconAsset,
    required this.onTap,
    required this.pressed,
    required this.onPressedStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    // No background, no splash. Only opacity feedback.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (onTap == null) return;
        onPressedStateChanged(true);
      },
      onTapUp: (_) {
        if (onTap == null) return;
        onPressedStateChanged(false);
      },
      onTapCancel: () {
        if (onTap == null) return;
        onPressedStateChanged(false);
      },
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: onTap == null ? 0.55 : (pressed ? 0.55 : 1.0),
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

class _ProviderLoginButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final VoidCallback? onTap;
  final bool pressed;
  final ValueChanged<bool> onPressedStateChanged;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Color chevronColor;

  const _ProviderLoginButton({
    required this.label,
    required this.iconAsset,
    required this.onTap,
    required this.pressed,
    required this.onPressedStateChanged,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.chevronColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (onTap == null) return;
        onPressedStateChanged(true);
      },
      onTapUp: (_) {
        if (onTap == null) return;
        onPressedStateChanged(false);
      },
      onTapCancel: () {
        if (onTap == null) return;
        onPressedStateChanged(false);
      },
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: onTap == null ? 0.60 : 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 350),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: borderColor == Colors.transparent
                  ? null
                  : Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 90),
                  opacity: pressed ? 0.55 : 1.0,
                  child: Image.asset(
                    iconAsset,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 90),
                  opacity: pressed ? 0.55 : 1.0,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
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

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  String? _error;

  late final GoogleSignIn _googleSignIn;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    final webClientId = ApiConfig.googleWebClientId.trim();

    _googleSignIn = GoogleSignIn(
      scopes: const <String>['email'],
      // For server-side ID token verification, prefer a Web OAuth client id here.
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );
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

  @override
  Widget build(BuildContext context) {
    final p = widget.p ?? Palette.from(Theme.of(context).colorScheme);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ 시스템 다크면 다크 배경, 라이트면 FAFAFA (기존 유지)
    final bg = widget.bg ?? (isDark ? p.bg : const Color(0xFFFAFAFA));

    // ✅ 다크에서 대비 보정 (너무 “밝은 회색”으로 뜨지 않게만)
    final copyColor = isDark ? p.muted.withOpacity(0.88) : p.muted;
    final errorColor = isDark ? p.muted.withOpacity(0.92) : p.muted;
    final footerColor = isDark
        ? p.muted.withOpacity(0.70)
        : p.muted.withOpacity(0.80);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BrandLogo(
                          p: p,
                          style: BrandLogoStyle.wordmark,
                          scale: 1.0,
                        ),
                        const SizedBox(height: 8),

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: copyColor,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                            children: [
                              const TextSpan(text: '문득 든 생각이 사라지기 전에'),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 1,
                                    bottom: 3,
                                  ),
                                  child: Text(
                                    '.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: p.accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize:
                                              (Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.fontSize ??
                                                  14) *
                                              1.3,
                                          height: 1.0,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 34),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: errorColor,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        _AuthText(
                          p: p,
                          label: 'Google로 시작하기',
                          enabled: !_loading,
                          onTap: _loginWithGoogle,
                        ),

                        if (_loading) ...[
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              // ✅ 다크에서 너무 죽지 않게
                              color: isDark
                                  ? p.muted.withOpacity(0.90)
                                  : p.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '© ${DateTime.now().year} bluelog. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: footerColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
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

    // ✅ 다크에서 “화이트 + 아주 약한 블루 틴트”
    // - 너무 파래지면 링크처럼 보여서 6~12% 정도만 권장
    Color tintWhite(Color tint, {double t = 0.10, double opacity = 0.94}) {
      final mixed = Color.lerp(Colors.white, tint, t)!;
      return mixed.withOpacity(opacity);
    }

    final enabledColor = isDark
        ? tintWhite(p.accent, t: 0.10, opacity: 0.84) // 👈 약한 푸른빛
        : p.ink;

    final disabledColor = isDark
        ? tintWhite(p.accent, t: 0.08, opacity: 0.55) // 👈 비활성도 약간 블루
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

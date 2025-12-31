import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/theme/palette.dart';

import 'package:lifelog_mobile/widgets/brand_logo.dart';

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

  static const _serverBaseUrl = String.fromEnvironment(
    'LIFELOG_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User canceled
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google idToken을 가져오지 못했습니다.');
      }

      final accessToken = await _exchangeGoogleIdTokenForAccessToken(idToken);

      // Persist for API calls
      await _secureStorage.write(key: 'accessToken', value: accessToken);

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

  Future<String> _exchangeGoogleIdTokenForAccessToken(String idToken) async {
    final uri = Uri.parse('$_serverBaseUrl/api/auth/oauth/google');

    final res = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'idToken': idToken}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('서버 로그인 실패 (${res.statusCode}): ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final token = map['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('서버 응답에 accessToken이 없습니다: ${res.body}');
    }

    return token;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p ?? Palette.from(Theme.of(context).colorScheme);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.bg ?? (isDark ? p.bg : const Color(0xFFFAFAFA));

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
                        // Logo (only strong emphasis)
                        BrandLogo(
                          p: p,
                          style: BrandLogoStyle.primary,
                          scale: 1.0,
                        ),
                        const SizedBox(height: 12),

                        // Copy (temporary placeholder — we’ll refine later)
                        Text(
                          '나도 몰랐던 나의 패턴을 발견하다.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: p.muted,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                        ),

                        const SizedBox(height: 34),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: p.muted,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Google only — pure text action
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
                              color: p.muted,
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
                  '© ${DateTime.now().year} lifelog. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: p.muted.withOpacity(0.80),
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

/// Minimal auth action:
/// - No icon, no arrow, no underline, no box
/// - Press feedback: subtle opacity only
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

    final color = widget.enabled ? p.ink : p.muted;
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

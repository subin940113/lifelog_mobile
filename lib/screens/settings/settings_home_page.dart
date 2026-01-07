import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../theme/theme_provider.dart';
import 'package:lifelog_mobile/theme/palette.dart';

import 'settings_routes.dart';
import 'theme_settings_page.dart';

import 'account_settings_page.dart';

import 'widgets/account_header.dart';
import 'widgets/settings_page_header.dart';
import 'widgets/settings_row.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'language_settings_page.dart';
import 'insight_setting_page.dart';

/// ✅ 기본 언어는 항상 한국어
const String _kDefaultLocaleId = 'ko_KR';

String _languageLabelFromLocaleId(String? localeId) {
  final id = (localeId ?? '').trim();

  // ✅ 저장값이 없으면 기본은 한국어로 표시
  if (id.isEmpty) return '한국어';

  final lower = id.toLowerCase();
  final head = lower.split(RegExp(r'[_-]')).first;

  // Prefer explicit variants first (so zh-Hant vs zh-Hans is stable)
  if (lower.contains('zh-hant') ||
      lower.contains('zh_hant') ||
      lower.contains('zh-tw') ||
      lower.contains('zh_tw') ||
      lower.contains('zh-hk') ||
      lower.contains('zh_hk')) {
    return '繁體中文';
  }
  if (lower.contains('zh-hans') ||
      lower.contains('zh_hans') ||
      lower.contains('zh-cn') ||
      lower.contains('zh_cn')) {
    return '简体中文';
  }

  switch (head) {
    case 'ko':
      return '한국어';
    case 'en':
      return 'English';
    case 'ja':
      return '日本語';
    case 'zh':
      return '中文';
    default:
      return id; // last resort
  }
}

class SettingsHomePage extends StatefulWidget {
  final VoidCallback? onOpenLanguage;

  final List<LocaleName>? languageLocales;
  final String? languageInitialLocaleId;
  final bool? languageIsListening;
  final ValueChanged<String?>? onApplyLanguage;

  final ValueChanged<ThemeMode> onChangeTheme;
  final VoidCallback? onLogout;

  /// Logged-in user's display name shown in the account header.
  /// If null, it will be loaded from secure storage.
  final String? accountName;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  const SettingsHomePage({
    super.key,
    this.onOpenLanguage,
    this.languageLocales,
    this.languageInitialLocaleId,
    this.languageIsListening,
    this.onApplyLanguage,
    required this.onChangeTheme,
    this.onLogout,
    this.accountName,
  });

  @override
  State<SettingsHomePage> createState() => _SettingsHomePageState();
}

class _SettingsHomePageState extends State<SettingsHomePage> {
  /// ✅ 저장된 localeId를 읽고, 없으면 기본(ko_KR)을 반환
  Future<String> _readLocaleOrDefault() async {
    final saved = await SettingsHomePage._secureStorage.read(
      key: kSttLocaleStorageKey,
    );
    final v = (saved ?? '').trim();
    return v.isEmpty ? _kDefaultLocaleId : v;
  }

  /// ✅ 기기 locales 안에서 "한국어 계열" 우선으로 찾아서 반환
  /// (ko_KR이 없으면 ko-* 중 첫번째, 그것도 없으면 fallback)
  String _pickKoreanOrFallback(List<LocaleName> locales) {
    if (locales.isEmpty) return _kDefaultLocaleId;

    bool isKo(LocaleName l) {
      final id = (l.localeId ?? '').toLowerCase();
      if (id.isEmpty) return false;
      final head = id.split(RegExp(r'[_-]')).first;
      return head == 'ko';
    }

    // 1) ko_KR 우선
    final exact = locales.where((l) => (l.localeId ?? '') == 'ko_KR').toList();
    if (exact.isNotEmpty) return exact.first.localeId!;

    // 2) ko-KR 우선
    final exactDash =
        locales.where((l) => (l.localeId ?? '') == 'ko-KR').toList();
    if (exactDash.isNotEmpty) return exactDash.first.localeId!;

    // 3) ko prefix 중 첫번째
    final koAny = locales.where(isKo).toList();
    if (koAny.isNotEmpty) return koAny.first.localeId ?? _kDefaultLocaleId;

    // 4) 그래도 없으면 첫 locale
    return locales.first.localeId ?? _kDefaultLocaleId;
  }

  Future<void> _openLanguageDefault(Palette p) async {
    // ✅ 1) initialLocaleId는 "저장값 > ko 우선 > fallback" 순서
    final saved = await _readLocaleOrDefault();

    final provided = widget.languageLocales;
    if (provided != null && provided.isNotEmpty) {
      final initial = provided.any((l) => (l.localeId ?? '') == saved)
          ? saved
          : _pickKoreanOrFallback(provided);

      await showLanguageSheet(
        context,
        bg: p.bg,
        p: p,
        locales: provided,
        initialLocaleId: initial,
        isListening: widget.languageIsListening ?? false,
        onApply: (localeId) {
          final cb = widget.onApplyLanguage;
          if (cb != null) cb(localeId);
        },
      );

      // ✅ 복귀 시 리프레시
      if (mounted) setState(() {});
      return;
    }

    final stt = SpeechToText();
    try {
      await stt.initialize();
      final locales = await stt.locales();

      final initial = locales.any((l) => (l.localeId ?? '') == saved)
          ? saved
          : _pickKoreanOrFallback(locales);

      await showLanguageSheet(
        context,
        bg: p.bg,
        p: p,
        locales: locales,
        initialLocaleId: initial,
        isListening: false,
        onApply: (localeId) {
          final cb = widget.onApplyLanguage;
          if (cb != null) cb(localeId);
        },
      );

      // ✅ 복귀 시 리프레시
      if (mounted) setState(() {});
    } catch (_) {
      await showLanguageSheet(
        context,
        bg: p.bg,
        p: p,
        locales: const <LocaleName>[],
        initialLocaleId: _kDefaultLocaleId,
        isListening: false,
        onApply: (localeId) {
          final cb = widget.onApplyLanguage;
          if (cb != null) cb(localeId);
        },
      );

      // ✅ 복귀 시 리프레시
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);
    final themeMode = context.watch<ThemeProvider>().mode;

    Future<void> openAccount() async {
      await pushSettingsPage<void>(
        context,
        AccountSettingsPage(p: p, onLogout: widget.onLogout),
      );
      if (!mounted) return;
      setState(() {});
    }

    void openInsightSettings() {
      pushSettingsPage<void>(
        context,
        InsightHubPage(p: p, onLogout: widget.onLogout),
      );
    }

    Future<void> openTerms() async {
      const url =
          'https://www.notion.so/bluelog-Terms-of-Service-Privacy-Policy-2e18e970a6f7800e825cc2a086fe430b?source=copy_link';
      final uri = Uri.parse(url);

      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('링크를 열 수 없어요.')),
          );
        }
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 여는 중 오류가 발생했어요.')),
        );
      }
    }

    Future<void> openLanguage() async {
      final override = widget.onOpenLanguage;
      if (override != null) {
        // override가 내부에서 push를 한다면, 복귀 리프레시를 위해
        // 여기서도 한 번 setState를 걸어줍니다.
        override();
        if (mounted) setState(() {});
        return;
      }
      await _openLanguageDefault(p);
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            SettingsPageHeader(
              title: '설정',
              titleColor: p.ink,
              iconColor: p.ink,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: openAccount,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: FutureBuilder<String?>(
                        future: widget.accountName != null
                            ? Future.value(widget.accountName)
                            : SettingsHomePage._secureStorage.read(
                                key: 'accountName',
                              ),
                        builder: (context, snapshot) {
                          final name =
                              (snapshot.data != null &&
                                      snapshot.data!.trim().isNotEmpty)
                                  ? snapshot.data!.trim()
                                  : '계정';
                          return AccountHeader(p: p, accountName: name);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel(text: '설정', p: p),
                  SettingsRow(
                    title: '테마',
                    onTap: () => showThemeSheet(
                      context,
                      p,
                      value: themeMode,
                      onChanged: widget.onChangeTheme,
                    ),
                    p: p,
                    trailingText: themeLabel(themeMode),
                  ),

                  /// ✅ 언어: 항상 storage 기준으로 표시 (없으면 한국어)
                  FutureBuilder<String>(
                    future: _readLocaleOrDefault(),
                    builder: (context, snapshot) {
                      final label = _languageLabelFromLocaleId(snapshot.data);
                      return SettingsRow(
                        title: '언어',
                        onTap: openLanguage,
                        p: p,
                        trailingText: label,
                      );
                    },
                  ),

                  SettingsRow(
                    title: '인사이트',
                    onTap: openInsightSettings,
                    p: p,
                  ),
                  SettingsRow(
                    title: '알림',
                    onTap: () => pushSettingsPage(
                      context,
                      const _PlaceholderSettingsPage(title: '알림'),
                    ),
                    p: p,
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel(text: '정보', p: p),
                  SettingsRow(
                    title: '이용 약관 및 개인정보 처리방침',
                    onTap: openTerms,
                    p: p,
                  ),
                  SettingsRow(
                    title: '버전 정보',
                    onTap: () {},
                    p: p,
                    trailingText: '1.0.0',
                    showChevron: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Palette p;
  const _SectionLabel({required this.text, required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: p.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _PlaceholderSettingsPage extends StatelessWidget {
  final String title;
  const _PlaceholderSettingsPage({required this.title});

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            SettingsPageHeader(
              title: title,
              titleColor: p.ink,
              iconColor: p.ink,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '준비 중',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: p.muted,
                        fontWeight: FontWeight.w600,
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
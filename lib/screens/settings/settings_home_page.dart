import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../theme/theme_provider.dart';
import 'package:lifelog_mobile/theme/palette.dart';

import 'settings_routes.dart';
import 'theme_setting_page.dart';
import 'account_setting_page.dart';
import 'language_setting_page.dart';
import 'insight_setting_page.dart';
import 'notification_setting_page.dart';
import 'widgets/account_header.dart';
import 'package:lifelog_mobile/widgets/app_page_header.dart';
import 'package:lifelog_mobile/widgets/app_safe_area.dart';
import 'widgets/settings_row.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// ✅ 기본 언어는 항상 한국어
const String _kDefaultLocaleId = 'ko_KR';

String _languageLabelFromLocaleId(String? localeId) {
  final id = (localeId ?? '').trim();
  if (id.isEmpty) return '한국어';

  final lower = id.toLowerCase();
  final head = lower.split(RegExp(r'[_-]')).first;

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
      return id;
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
  Future<String> _readLocaleOrDefault() async {
    final saved = await SettingsHomePage._secureStorage.read(
      key: kSttLocaleStorageKey,
    );
    final v = (saved ?? '').trim();
    return v.isEmpty ? _kDefaultLocaleId : v;
  }

  String _pickKoreanOrFallback(List<LocaleName> locales) {
    if (locales.isEmpty) return _kDefaultLocaleId;

    bool isKo(LocaleName l) {
      final id = (l.localeId ?? '').toLowerCase();
      if (id.isEmpty) return false;
      return id.split(RegExp(r'[_-]')).first == 'ko';
    }

    final exact = locales.where((l) => (l.localeId ?? '') == 'ko_KR').toList();
    if (exact.isNotEmpty) return exact.first.localeId!;

    final exactDash = locales
        .where((l) => (l.localeId ?? '') == 'ko-KR')
        .toList();
    if (exactDash.isNotEmpty) return exactDash.first.localeId!;

    final koAny = locales.where(isKo).toList();
    if (koAny.isNotEmpty) return koAny.first.localeId ?? _kDefaultLocaleId;

    return locales.first.localeId ?? _kDefaultLocaleId;
  }

  Future<void> _openLanguageDefault(Palette p) async {
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
      if (mounted) setState(() {});
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
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: AppPageHeader(
          title: '',
          titleColor: p.ink,
          iconColor: p.ink,
          leading: AppPageHeaderLeading.close, // ✅ 수정 완료
        ),
      ),
      body: AppSafeArea(
        backSwipeEnabled: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: openAccount,
              child: FutureBuilder<String?>(
                future: widget.accountName != null
                    ? Future.value(widget.accountName)
                    : SettingsHomePage._secureStorage.read(key: 'accountName'),
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
            const SizedBox(height: 30),
            _SectionLabel(text: '설정', p: p),
            SettingsRow(
              title: '테마',
              p: p,
              trailingText: themeLabel(themeMode),
              onTap: () => showThemeSheet(
                context,
                p,
                value: themeMode,
                onChanged: widget.onChangeTheme,
              ),
            ),
            FutureBuilder<String>(
              future: _readLocaleOrDefault(),
              builder: (context, snapshot) {
                return SettingsRow(
                  title: '언어',
                  p: p,
                  trailingText: _languageLabelFromLocaleId(snapshot.data),
                  onTap: () async {
                    final override = widget.onOpenLanguage;
                    if (override != null) {
                      override();
                      if (mounted) setState(() {});
                      return;
                    }
                    await _openLanguageDefault(p);
                  },
                );
              },
            ),
            SettingsRow(title: '인사이트', p: p, onTap: openInsightSettings),
            SettingsRow(
              title: '알림',
              p: p,
              onTap: () => pushSettingsPage<void>(
                context,
                NotificationSettingPage(p: p, onLogout: widget.onLogout),
              ),
            ),
            const SizedBox(height: 30),
            _SectionLabel(text: '정보', p: p),
            SettingsRow(title: '이용 약관 및 개인정보 처리방침', p: p, onTap: openTerms),
            const SizedBox(height: 10),
            SettingsRow(
              title: '버전 정보',
              p: p,
              trailingText: '1.0.0',
              showChevron: false,
              onTap: () {},
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
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: p.muted.withOpacity(0.7),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

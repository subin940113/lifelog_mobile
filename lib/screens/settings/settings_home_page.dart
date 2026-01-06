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
import 'language_settings_page.dart';
import 'insight_setting_page.dart';

class SettingsHomePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);
    final themeMode = context.watch<ThemeProvider>().mode;

    Future<void> _openLanguageDefault() async {
      final provided = languageLocales;
      if (provided != null && provided.isNotEmpty) {
        showLanguageSheet(
          context,
          bg: p.bg,
          p: p,
          locales: provided,
          initialLocaleId: languageInitialLocaleId,
          isListening: languageIsListening ?? false,
          onApply: (localeId) {
            final cb = onApplyLanguage;
            if (cb != null) cb(localeId);
          },
        );
        return;
      }

      final stt = SpeechToText();
      try {
        await stt.initialize();
        final locales = await stt.locales();
        final system = await stt.systemLocale();

        showLanguageSheet(
          context,
          bg: p.bg,
          p: p,
          locales: locales,
          initialLocaleId: system?.localeId,
          isListening: false,
          onApply: (localeId) {
            final cb = onApplyLanguage;
            if (cb != null) cb(localeId);
          },
        );
      } catch (_) {
        showLanguageSheet(
          context,
          bg: p.bg,
          p: p,
          locales: const <LocaleName>[],
          initialLocaleId: null,
          isListening: false,
          onApply: (localeId) {
            final cb = onApplyLanguage;
            if (cb != null) cb(localeId);
          },
        );
      }
    }

    void openLanguage() {
      final override = onOpenLanguage;
      if (override != null) {
        override();
        return;
      }
      _openLanguageDefault();
    }

    void openAccount() {
      pushSettingsPage<void>(
        context,
        AccountSettingsPage(
          p: p,
          onLogout: onLogout,
        ),
      );
    }

    void openInsightSettings() {
      pushSettingsPage<void>(
        context,
        InsightHubPage(
          p: p,
          onLogout: onLogout,
        ),
      );
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
                        future: accountName != null
                            ? Future.value(accountName)
                            : _secureStorage.read(key: 'accountName'),
                        builder: (context, snapshot) {
                          final name = (snapshot.data != null && snapshot.data!.trim().isNotEmpty)
                              ? snapshot.data!.trim()
                              : '계정';

                          return AccountHeader(
                            p: p,
                            accountName: name,
                          );
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
                      onChanged: onChangeTheme,
                    ),
                    p: p,
                    trailingText: themeLabel(themeMode),
                  ),

                  SettingsRow(title: '언어', onTap: openLanguage, p: p),

                  // ✅ 인사이트 설정 메뉴 추가
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
                    onTap: () => pushSettingsPage(
                      context,
                      const _PlaceholderSettingsPage(
                        title: '이용 약관 및 개인정보 처리방침',
                      ),
                    ),
                    p: p,
                  ),

                  SettingsRow(
                    title: '버전 정보',
                    onTap: () {},
                    p: p,
                    trailingText: '0.1.0',
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/theme_provider.dart';
import '../record/journal_palette.dart';

import 'settings_routes.dart';
import 'theme_settings_page.dart';

import 'widgets/account_header.dart';
import 'widgets/settings_page_header.dart';
import 'widgets/settings_row.dart';

class SettingsHomePage extends StatelessWidget {
  // ⚠️ 언어는 여기서 직접 push하지 않고 콜백 유지
  // 단, 이 콜백 내부에서 showLanguageSheet(...)를 쓰도록 바꾸면 언어도 오른쪽 전환됨
  final VoidCallback onOpenLanguage;

  final ValueChanged<ThemeMode> onChangeTheme;

  const SettingsHomePage({
    super.key,
    required this.onOpenLanguage,
    required this.onChangeTheme,
  });

  @override
  Widget build(BuildContext context) {
    final p = JournalPalette.from(Theme.of(context).colorScheme);
    final themeMode = context.watch<ThemeProvider>().mode;

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
                  AccountHeader(p: p),
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

                  // ✅ 언어도 오른쪽 전환으로 통일하려면
                  // onOpenLanguage 콜백이 showLanguageSheet(...)를 사용하도록 구현되어야 함
                  SettingsRow(title: '언어', onTap: onOpenLanguage, p: p),

                  // ✅ 나머지 메뉴는 전부 오른쪽 전환으로 통일
                  SettingsRow(
                    title: '알림',
                    onTap: () => pushSettingsPage(
                      context,
                      const _PlaceholderSettingsPage(title: '알림'),
                    ),
                    p: p,
                  ),

                  SettingsRow(
                    title: 'PIN 잠금',
                    onTap: () => pushSettingsPage(
                      context,
                      const _PlaceholderSettingsPage(title: 'PIN 잠금'),
                    ),
                    p: p,
                    trailing: SwitchTheme(
                      data: SwitchThemeData(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        splashRadius: 0,
                        thumbColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) return p.bg;
                          return p.muted.withOpacity(0.45);
                        }),
                        trackColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return p.ink.withOpacity(0.55);
                          }
                          return p.muted.withOpacity(0.18);
                        }),
                        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return p.ink.withOpacity(0.35);
                          }
                          return p.muted.withOpacity(0.28);
                        }),
                      ),
                      child: SizedBox(
                        width: 46,
                        height: 28,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Switch(
                            value: false,
                            onChanged: (_) {},
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ),
                    showChevron: false,
                  ),

                  const SizedBox(height: 18),
                  _SectionLabel(text: '정보', p: p),

                  SettingsRow(
                    title: '문의하기',
                    onTap: () => pushSettingsPage(
                      context,
                      const _PlaceholderSettingsPage(title: '문의하기'),
                    ),
                    p: p,
                  ),
                  SettingsRow(
                    title: '이용 약관 및 개인정보 처리방침',
                    onTap: () => pushSettingsPage(
                      context,
                      const _PlaceholderSettingsPage(title: '이용 약관 및 개인정보 처리방침'),
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
  final JournalPalette p;
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
    final p = JournalPalette.from(Theme.of(context).colorScheme);

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
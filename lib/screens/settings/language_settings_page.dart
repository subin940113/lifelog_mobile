import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'widgets/settings_page_header.dart';

// ✅ Glass 공통 컴포넌트
import 'package:lifelog_mobile/widgets/glass_dot.dart';

void showLanguageSheet(
  BuildContext context, {
  required Color bg,
  required Palette p,
  required List<LocaleName> locales,
  required String? initialLocaleId,
  required bool isListening,
  required OnApplySettings onApply,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => LanguageSettingsPage(
        bg: bg,
        p: p,
        locales: locales,
        initialLocaleId: initialLocaleId,
        isListening: isListening,
        onApply: onApply,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    ),
  );
}

typedef OnApplySettings = void Function(String? localeId);

class LanguageSettingsPage extends StatefulWidget {
  final Color bg;
  final Palette p;
  final List<LocaleName> locales;
  final String? initialLocaleId;
  final bool isListening;
  final OnApplySettings onApply;

  const LanguageSettingsPage({
    super.key,
    required this.bg,
    required this.p,
    required this.locales,
    required this.initialLocaleId,
    required this.isListening,
    required this.onApply,
  });

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  String? _localeId;

  @override
  void initState() {
    super.initState();
    _localeId = widget.initialLocaleId;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    const allowedPrefixes = <String>{'ko', 'en', 'ja', 'zh'};

    final allLocales = widget.locales;

    final filteredLocales = allLocales.where((l) {
      final id = (l.localeId ?? '').toLowerCase();
      if (id.isEmpty) return false;
      final prefix = id.split(RegExp(r'[_-]')).first;
      return allowedPrefixes.contains(prefix);
    }).toList();

    final locales = filteredLocales.isNotEmpty ? filteredLocales : allLocales;

    final selectedId = (locales.any((l) => l.localeId == _localeId))
        ? _localeId
        : (locales.isNotEmpty ? locales.first.localeId : _localeId);

    final displayLocales = [...locales]
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: widget.bg,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            SettingsPageHeader(
              title: '언어',
              titleColor: p.ink,
              iconColor: p.ink,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                itemCount: displayLocales.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: p.muted.withOpacity(0.10),
                ),
                itemBuilder: (context, index) {
                  final l = displayLocales[index];
                  final selected = l.localeId == selectedId;

                  return InkWell(
                    onTap: widget.isListening
                        ? null
                        : () {
                            setState(() => _localeId = l.localeId);
                            widget.onApply(l.localeId);
                          },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.name,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: p.ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          if (selected)
                            GlassDot(size: 10, color: p.accent, active: false)
                          else
                            const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

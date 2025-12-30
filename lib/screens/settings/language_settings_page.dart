import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../record/journal_palette.dart';
import 'widgets/settings_page_header.dart';

void showLanguageSheet(
  BuildContext context, {
  required Color bg,
  required JournalPalette p,
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
  final JournalPalette p;
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

    // Keep the list minimal: only widely used languages.
    // We filter by localeId prefix because speech_to_text localeIds can vary by region.
    const allowedPrefixes = <String>{
      'ko', // Korean
      'en', // English
      'ja', // Japanese
      'zh', // Chinese (Simplified/Traditional)
      // 'es', // Spanish
      // 'fr', // French
      // 'de', // German
      // 'pt', // Portuguese (PT/BR)
      // 'it', // Italian
    };

    final allLocales = widget.locales;

    final filteredLocales = allLocales
        .where((l) {
          final id = (l.localeId ?? '').toLowerCase();
          if (id.isEmpty) return false;
          // localeId can be like `en_US` or `en-US` depending on platform.
          final prefix = id.split(RegExp(r'[_-]')).first;
          return allowedPrefixes.contains(prefix);
        })
        .toList();

    // If filtering produces an empty list (device returns unexpected localeId formats),
    // fall back to the original list so the screen never becomes blank.
    final locales = filteredLocales.isNotEmpty ? filteredLocales : allLocales;

    // If the initial selection is not in the filtered list, fall back to the first available.
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
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: p.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (selected)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: p.accent,
                                shape: BoxShape.circle,
                              ),
                            )
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
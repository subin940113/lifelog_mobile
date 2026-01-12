import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/app_page_header.dart';
import 'package:lifelog_mobile/widgets/app_safe_area.dart';

import 'package:lifelog_mobile/widgets/glass_dot.dart';

typedef OnApplySettings = void Function(String? localeId);

const String kSttLocaleStorageKey = 'sttLocaleId';

/// ✅ 기본은 항상 한국어
const String _kDefaultLocaleId = 'ko_KR';

Future<String?> showLanguageSheet(
  BuildContext context, {
  required Color bg,
  required Palette p,
  required List<LocaleName> locales,
  required String? initialLocaleId,
  required bool isListening,
  required OnApplySettings onApply,
}) {
  return Navigator.of(context).push<String?>(
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

/// ✅ 완전 하드코딩: UI에 노출할 언어 정의
class _HardcodedLang {
  final String key;
  final String label;
  final List<String> preferredLocaleIds;
  final List<String> preferredPrefixes;

  const _HardcodedLang({
    required this.key,
    required this.label,
    required this.preferredLocaleIds,
    required this.preferredPrefixes,
  });
}

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
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // ✅ UI에 보여줄 언어는 여기서만 관리
  static const List<_HardcodedLang> _langs = <_HardcodedLang>[
    _HardcodedLang(
      key: 'ko',
      label: '한국어',
      preferredLocaleIds: <String>['ko_KR', 'ko-KR', 'ko'],
      preferredPrefixes: <String>['ko'],
    ),
    _HardcodedLang(
      key: 'en',
      label: 'English',
      preferredLocaleIds: <String>[
        'en_US',
        'en-US',
        'en_GB',
        'en-GB',
        'en_AU',
        'en-AU',
        'en',
      ],
      preferredPrefixes: <String>['en'],
    ),
    _HardcodedLang(
      key: 'ja',
      label: '日本語',
      preferredLocaleIds: <String>['ja_JP', 'ja-JP', 'ja'],
      preferredPrefixes: <String>['ja'],
    ),
    _HardcodedLang(
      key: 'zh-Hans',
      label: '简体中文',
      preferredLocaleIds: <String>[
        'zh_CN',
        'zh-CN',
        'zh_Hans_CN',
        'zh-Hans-CN',
        'zh_Hans',
        'zh-Hans',
        'zh',
      ],
      preferredPrefixes: <String>['zh', 'zh-hans'],
    ),
    _HardcodedLang(
      key: 'zh-Hant',
      label: '繁體中文',
      preferredLocaleIds: <String>[
        'zh_TW',
        'zh-TW',
        'zh_Hant_TW',
        'zh-Hant-TW',
        'zh_Hant',
        'zh-Hant',
        'zh_HK',
        'zh-HK',
      ],
      preferredPrefixes: <String>['zh-hant', 'zh'],
    ),
  ];

  String? _localeId;
  bool _loadedStored = false;

  @override
  void initState() {
    super.initState();
    _localeId = widget.initialLocaleId;
    _loadStoredOrSetDefault();
  }

  String _norm(String? s) => (s ?? '').trim();

  String _prefixOf(String id) {
    final lower = id.toLowerCase();
    return lower.split(RegExp(r'[_-]')).first;
  }

  bool _deviceSupports(String id) {
    final target = _norm(id);
    if (target.isEmpty) return false;
    return widget.locales.any((l) => _norm(l.localeId) == target);
  }

  String? _pickSupportedLocaleId(_HardcodedLang lang) {
    if (widget.locales.isEmpty) return null;

    final all = widget.locales
        .map((l) => _norm(l.localeId))
        .where((id) => id.isNotEmpty)
        .toList();

    for (final wanted in lang.preferredLocaleIds) {
      final w = _norm(wanted);
      if (w.isEmpty) continue;
      if (all.any((id) => _norm(id) == w)) return w;
    }

    for (final pref in lang.preferredPrefixes) {
      final pfx = _norm(pref).toLowerCase();
      for (final id in all) {
        if (_prefixOf(id) == pfx) return id;
      }
    }

    return null;
  }

  List<_LangRowVm> _buildRows() {
    final rows = <_LangRowVm>[];
    for (final lang in _langs) {
      final supported = _pickSupportedLocaleId(lang);
      if (supported == null) continue;
      rows.add(_LangRowVm(lang: lang, localeId: supported));
    }
    return rows;
  }

  Future<void> _loadStoredOrSetDefault() async {
    final savedRaw = await _storage.read(key: kSttLocaleStorageKey);
    final saved = _norm(savedRaw);

    String resolved;

    if (saved.isNotEmpty && _deviceSupports(saved)) {
      resolved = saved;
    } else {
      final rows = _buildRows();
      final koRow = rows.where((r) => r.lang.key == 'ko').toList();
      resolved = koRow.isNotEmpty ? koRow.first.localeId : _kDefaultLocaleId;
      await _storage.write(key: kSttLocaleStorageKey, value: resolved);
    }

    if (!mounted) return;
    setState(() {
      _localeId = resolved;
      _loadedStored = true;
    });

    widget.onApply(resolved);
  }

  Future<void> _selectLocale(String? id) async {
    if (widget.isListening) return;

    final v = _norm(id);
    if (v.isEmpty) return;

    setState(() => _localeId = v);

    await _storage.write(key: kSttLocaleStorageKey, value: v);
    if (!mounted) return;

    widget.onApply(v);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final rows = _buildRows();

    String? effectiveSelected;
    if (rows.any((r) => _norm(r.localeId) == _norm(_localeId))) {
      effectiveSelected = _localeId;
    } else {
      final ko = rows.where((r) => r.lang.key == 'ko').toList();
      effectiveSelected = ko.isNotEmpty
          ? ko.first.localeId
          : (rows.isNotEmpty ? rows.first.localeId : _localeId);
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_localeId);
        return false;
      },
      child: Scaffold(
        backgroundColor: widget.bg,
        appBar: AppBar(
          backgroundColor: p.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: AppPageHeader(title: '', titleColor: p.ink, iconColor: p.ink),
        ),
        body: AppSafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ✅ 리스트와 동일한 좌우(18) 라인으로 타이틀/설명 정렬
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '언어',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '선택한 언어로 음성을 인식해요.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: p.muted.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: !_loadedStored
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '불러오는 중…',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: p.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox.shrink(),
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          final selected =
                              _norm(row.localeId) == _norm(effectiveSelected);

                          return InkWell(
                            onTap: widget.isListening
                                ? null
                                : () => _selectLocale(row.localeId),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: SizedBox(
                              height: 48,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      row.lang.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: p.ink,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 18,
                                          ),
                                    ),
                                  ),
                                  if (selected)
                                    GlassDot(
                                      size: 12,
                                      color: p.accent,
                                      active: false,
                                    )
                                  else
                                    const SizedBox(width: 12),
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
      ),
    );
  }
}

class _LangRowVm {
  final _HardcodedLang lang;
  final String localeId;

  const _LangRowVm({required this.lang, required this.localeId});
}

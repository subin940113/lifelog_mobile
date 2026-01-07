import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'widgets/settings_page_header.dart';

import 'package:lifelog_mobile/widgets/glass_dot.dart';

typedef OnApplySettings = void Function(String? localeId);

const String kSttLocaleStorageKey = 'sttLocaleId';

/// ✅ 기본은 항상 한국어
const String _kDefaultLocaleId = 'ko_KR';

/// ✅ (중요) 이제 Future로 결과를 돌려줌.
/// SettingsHomePage에서 await 가능 -> 복귀 시 리프레시 트리거 가능
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
  final String key; // 내부 식별자
  final String label; // 화면 표시명(해당 언어로)
  final List<String> preferredLocaleIds; // 우선순위 localeId 후보들
  final List<String> preferredPrefixes; // 위 후보가 없을 때 prefix로 보정

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

  String? _localeId; // 실제 저장되는 값 (STT localeId)
  bool _loadedStored = false;

  @override
  void initState() {
    super.initState();
    // initialLocaleId는 “표시용 초기값”일 뿐이고,
    // 실제 선택값 확정은 storage를 기준으로 맞춤
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

  /// ✅ 기기 지원 locale 목록에서, 특정 언어에 대해 “대표 localeId”를 하나 고른다.
  String? _pickSupportedLocaleId(_HardcodedLang lang) {
    if (widget.locales.isEmpty) return null;

    final all = widget.locales
        .map((l) => _norm(l.localeId))
        .where((id) => id.isNotEmpty)
        .toList();

    // 1) localeId exact 우선순위 매칭
    for (final wanted in lang.preferredLocaleIds) {
      final w = _norm(wanted);
      if (w.isEmpty) continue;
      if (all.any((id) => _norm(id) == w)) return w;
    }

    // 2) prefix로 fallback
    for (final pref in lang.preferredPrefixes) {
      final pfx = _norm(pref).toLowerCase();
      for (final id in all) {
        if (_prefixOf(id) == pfx) return id;
      }
    }

    return null;
  }

  /// ✅ UI에 보여줄 언어 리스트(기기 지원되는 것만)
  List<_LangRowVm> _buildRows() {
    final rows = <_LangRowVm>[];
    for (final lang in _langs) {
      final supported = _pickSupportedLocaleId(lang);
      if (supported == null) continue;
      rows.add(_LangRowVm(lang: lang, localeId: supported));
    }
    return rows;
  }

  /// ✅ 저장값이 없으면 "항상 한국어"를 기본으로 확정해 storage에 써 둠
  Future<void> _loadStoredOrSetDefault() async {
    final savedRaw = await _storage.read(key: kSttLocaleStorageKey);
    final saved = _norm(savedRaw);

    String resolved;

    if (saved.isNotEmpty && _deviceSupports(saved)) {
      resolved = saved;
    } else {
      // 저장값이 없거나, 저장값이 기기 지원 목록에 없으면 -> 한국어로 고정
      // (기기에서 ko_KR이 없을 수도 있으니, 지원되는 ko를 하나 찾고 없으면 fallback)
      final rows = _buildRows();
      final koRow =
          rows.where((r) => r.lang.key == 'ko').cast<_LangRowVm?>().toList();
      resolved = koRow.isNotEmpty ? koRow.first!.localeId : _kDefaultLocaleId;

      // ✅ 기본값을 storage에 “명시적으로” 저장해 둠
      await _storage.write(key: kSttLocaleStorageKey, value: resolved);
    }

    if (!mounted) return;
    setState(() {
      _localeId = resolved;
      _loadedStored = true;
    });

    // ✅ 즉시 반영 (RecordScreen 등 즉시 언어 갱신 가능)
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

    // 표시상 선택값 보정: 현재 _localeId가 rows 안에 없으면 한국어(있으면) or 첫 항목
    String? effectiveSelected;
    if (rows.any((r) => _norm(r.localeId) == _norm(_localeId))) {
      effectiveSelected = _localeId;
    } else {
      final ko = rows.where((r) => r.lang.key == 'ko').toList();
      effectiveSelected = ko.isNotEmpty ? ko.first.localeId : (rows.isNotEmpty ? rows.first.localeId : _localeId);
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_localeId); // ✅ SettingsHomePage에서 await로 수신 가능
        return false;
      },
      child: Scaffold(
        backgroundColor: widget.bg,
        appBar: null,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsPageHeader(
                title: '언어',
                titleColor: p.ink,
                iconColor: p.ink,
              ),

              // ✅ 안내문: 왼쪽 패딩 문제는 Align 제거하고 Row/Expanded로 고정하면 깔끔해짐
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '선택한 언어는 기록 말하기에서 음성 인식 언어로 사용돼요.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: p.muted.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: !_loadedStored
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '불러오는 중…',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  final String localeId; // 실제 STT에 전달/저장되는 값

  const _LangRowVm({required this.lang, required this.localeId});
}
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'widgets/settings_page_header.dart';

// ✅ Glass 공통 컴포넌트
import 'package:lifelog_mobile/widgets/glass_dot.dart';

typedef OnApplySettings = void Function(String? localeId);

const String kSttLocaleStorageKey = 'sttLocaleId';

/// ✅ 한국 사용자 기준 “자주 쓰는 언어”만 노출 (기기 지원되는 것만 표시)
/// - 정렬은 고정(가나다 X) : ko → en → ja → zh
/// - 저장된 선택값이 top set에 없으면 맨 위에 1개 추가로 보여줌(선택값 보존 UX)
const List<String> _krTopLocaleIds = <String>[
  // Korean
  'ko_KR', 'ko-KR', 'ko',

  // English
  'en_US', 'en-US', 'en_GB', 'en-GB', 'en',

  // Japanese
  'ja_JP', 'ja-JP', 'ja',

  // Chinese (Simplified / Traditional)
  'zh_CN', 'zh-CN', 'zh_Hans_CN', 'zh-Hans-CN', 'zh_Hans', 'zh-Hans',
  'zh_TW', 'zh-TW', 'zh_Hant_TW', 'zh-Hant-TW', 'zh_Hant', 'zh-Hant',
  'zh_HK', 'zh-HK', 'zh',
];

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

  String? _localeId;
  bool _loadedStored = false;

  @override
  void initState() {
    super.initState();
    _localeId = widget.initialLocaleId;
    _loadStoredIfNeeded();
  }

  Future<void> _loadStoredIfNeeded() async {
    final saved = await _storage.read(key: kSttLocaleStorageKey);
    if (!mounted) return;

    if (saved != null && widget.locales.any((l) => l.localeId == saved)) {
      setState(() {
        _localeId = saved;
        _loadedStored = true;
      });
      return;
    }

    setState(() => _loadedStored = true);
  }

  Future<void> _selectLocale(String? id) async {
    if (widget.isListening) return;

    setState(() => _localeId = id);

    await _storage.write(key: kSttLocaleStorageKey, value: id);
    if (!mounted) return;

    widget.onApply(id);
  }

  String _norm(String? s) => (s ?? '').trim();

  bool _isBareCode(String id) => !id.contains('_') && !id.contains('-');

  List<LocaleName> _buildKrTopLocales({
    required List<LocaleName> all,
    required String? selectedId,
  }) {
    if (all.isEmpty) return const <LocaleName>[];

    // localeId -> LocaleName
    final byId = <String, LocaleName>{};
    for (final l in all) {
      final id = _norm(l.localeId);
      if (id.isNotEmpty) byId[id] = l;
    }

    final picked = <LocaleName>[];
    final used = <String>{};

    LocaleName? findByPrefix(String prefix) {
      final pfx = prefix.toLowerCase();
      for (final l in all) {
        final id = _norm(l.localeId);
        if (id.isEmpty) continue;
        final head = id.toLowerCase().split(RegExp(r'[_-]')).first;
        if (head == pfx) return l;
      }
      return null;
    }

    void addIfNew(LocaleName? l) {
      if (l == null) return;
      final id = _norm(l.localeId);
      if (id.isEmpty) return;
      if (used.add(id)) picked.add(l);
    }

    // 1) Top set in fixed priority order
    for (final wanted in _krTopLocaleIds) {
      final exact = byId[wanted];
      if (exact != null) {
        addIfNew(exact);
        continue;
      }

      if (_isBareCode(wanted)) {
        addIfNew(findByPrefix(wanted));
      }
    }

    // 2) Keep the selected locale visible even if it's outside the top set
    final sel = _norm(selectedId);
    if (sel.isNotEmpty && byId[sel] != null && !used.contains(sel)) {
      picked.insert(0, byId[sel]!);
      used.add(sel);
    }

    // 3) If still empty (rare), fallback to ko/en/ja/zh prefix-filtered list
    if (picked.isEmpty) {
      const prefixes = <String>{'ko', 'en', 'ja', 'zh'};
      return all.where((l) {
        final id = _norm(l.localeId).toLowerCase();
        if (id.isEmpty) return false;
        final head = id.split(RegExp(r'[_-]')).first;
        return prefixes.contains(head);
      }).toList();
    }

    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    final selectedId = _localeId;
    final displayLocales = _buildKrTopLocales(
      all: widget.locales,
      selectedId: selectedId,
    );

    // 선택값이 목록에 없으면 첫 항목을 “표시상” 선택으로 처리
    final effectiveSelectedId =
        (displayLocales.any((l) => _norm(l.localeId) == _norm(selectedId)))
        ? selectedId
        : (displayLocales.isNotEmpty
              ? displayLocales.first.localeId
              : selectedId);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_localeId);
        return false;
      },
      child: Scaffold(
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
                        itemCount: displayLocales.length,
                        separatorBuilder: (_, __) => const SizedBox.shrink(),
                        itemBuilder: (context, index) {
                          final l = displayLocales[index];
                          final selected =
                              _norm(l.localeId) == _norm(effectiveSelectedId);

                          return InkWell(
                            onTap: widget.isListening
                                ? null
                                : () => _selectLocale(l.localeId),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: SizedBox(
                              height: 48,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.name,
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

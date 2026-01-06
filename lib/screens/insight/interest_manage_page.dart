import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/interest_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/models/interest_state.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/app_page_header.dart';
import 'package:lifelog_mobile/widgets/app_toast.dart';

import 'widgets/interest_badge.dart';

class InterestManagePage extends StatefulWidget {
  final Palette p;
  final VoidCallback? onLogout;

  const InterestManagePage({
    super.key,
    required this.p,
    this.onLogout,
  });

  @override
  State<InterestManagePage> createState() => _InterestManagePageState();
}

class _InterestManagePageState extends State<InterestManagePage> {
  static const int _maxKeywords = 5;

  // API
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  late final AuthApiClient _authApi;
  late final InterestApiClient _interestApi;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _loading = true;
  bool _saving = false;

  List<String> _keywords = const [];
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _storage,
      onUnauthorized: widget.onLogout,
    );
    _interestApi = InterestApiClient(_authApi);

    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    if (!mounted) return;
    AppToast.show(context, message);
  }

  void _setError(String? v) {
    if (!mounted) return;
    setState(() => _errorText = v);
  }

  String _normalize(String input) => input.trim();
  bool _equalsIgnoreCase(String a, String b) => a.toLowerCase() == b.toLowerCase();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final InterestState s = await _interestApi.getInterests();
      if (!mounted) return;
      setState(() {
        _keywords = s.keywords;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showToast('불러오지 못했어요');
    }
  }

  Future<void> _addKeyword() async {
    if (_saving) return;

    final keyword = _normalize(_controller.text);

    if (keyword.isEmpty) {
      _setError(null);
      return;
    }

    if (_keywords.length >= _maxKeywords) {
      _setError('관심사는 최대 $_maxKeywords개까지 등록할 수 있어요.');
      return;
    }

    final exists = _keywords.any((k) => _equalsIgnoreCase(k, keyword));
    if (exists) {
      _setError('이미 등록된 키워드예요.');
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      final s = await _interestApi.addKeyword(keyword);
      if (!mounted) return;

      setState(() {
        _keywords = s.keywords;
        _controller.clear();
      });

      _showToast('저장했습니다.');
      FocusScope.of(context).requestFocus(_focusNode);
    } catch (_) {
      if (!mounted) return;
      _showToast('저장에 실패했어요. 네트워크를 확인해주세요');
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Future<void> _removeKeyword(String keyword) async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      final s = await _interestApi.removeKeyword(keyword);
      if (!mounted) return;

      setState(() {
        _keywords = s.keywords;
      });

      _showToast('저장했습니다.');
    } catch (_) {
      if (!mounted) return;
      _showToast('저장에 실패했어요. 네트워크를 확인해주세요');
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final underlineColor = p.outline.withOpacity(0.85);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: AppPageHeader(
          title: '관심사',
          titleColor: p.ink,
          iconColor: p.ink,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          children: [
            if (_loading)
              Text(
                '불러오는 중…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: p.muted,
                      fontWeight: FontWeight.w500,
                    ),
              )
            else ...[
              Text(
                '관심사를 등록하면 키워드 기반으로 인사이트가 생성돼요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: p.muted,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 14),

              // ✅ 한 덩어리: 입력 → (에러) → 배지 → 메타
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            cursorColor: p.accent,
                            enabled: !_saving,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: p.ink,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.only(top: 6, bottom: 8),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: underlineColor, width: 1),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: underlineColor, width: 1),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: p.accent.withOpacity(0.9), width: 1),
                              ),
                              hintText: '키워드 입력',
                              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: p.muted.withOpacity(0.65),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addKeyword(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: SizedBox(
                          height: 34,
                          child: TextButton(
                            onPressed: _saving ? null : _addKeyword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: const Size(0, 34),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              splashFactory: NoSplash.splashFactory,
                              foregroundColor: p.accent,
                            ),
                            child: Text(
                              _saving ? '저장…' : '추가',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: p.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 1.0,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorText!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: p.muted,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Badges
                  if (_keywords.isEmpty)
                    Text(
                      '아직 등록된 관심사가 없어요.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: p.muted.withOpacity(0.75),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in _keywords)
                          InkWell(
                            onTap: _saving ? null : () => _removeKeyword(k),
                            borderRadius: BorderRadius.circular(999),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: InterestBadge(p: p, text: k),
                          ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Meta line (same block rhythm)
                  Row(
                    children: [
                      Text(
                        '${_keywords.length}/$_maxKeywords',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: p.muted.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '태그를 탭하면 삭제돼요.',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: p.muted.withOpacity(0.75),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
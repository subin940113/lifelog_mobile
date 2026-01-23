import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/interest_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/models/interest_state.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/app_page_header.dart';
import 'package:lifelog_mobile/widgets/app_safe_area.dart';
import 'package:lifelog_mobile/widgets/app_toast.dart';
import 'package:lifelog_mobile/widgets/glass_fab.dart';

import 'widgets/interest_badge.dart';

class InterestSettingPage extends StatefulWidget {
  final Palette p;
  final VoidCallback? onLogout;

  const InterestSettingPage({super.key, required this.p, this.onLogout});

  @override
  State<InterestSettingPage> createState() => _InterestSettingPageState();
}

class _InterestSettingPageState extends State<InterestSettingPage> {
  static const int _maxKeywords = 5;
  static const int _maxKeywordLen = 80;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  late final AuthApiClient _authApi;
  late final InterestApiClient _interestApi;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ✅ RecordScreen처럼 FAB 위치 기준 토스트를 위해 key 사용
  final GlobalKey _fabKey = GlobalKey();

  bool _loading = true;
  bool _saving = false;

  List<String> _keywords = const [];
  String? _errorText;

  String _normalize(String input) => input.trim();
  bool _equalsIgnoreCase(String a, String b) =>
      a.toLowerCase() == b.toLowerCase();

  String get _input => _normalize(_controller.text);
  bool get _fabVisible => _input.isNotEmpty;
  bool get _fabEnabled => !_loading && !_saving;

  @override
  void initState() {
    super.initState();

    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _storage,
      onUnauthorized: widget.onLogout,
    );
    _interestApi = InterestApiClient(_authApi);

    _controller.addListener(() {
      if (!mounted) return;
      setState(() {}); // FAB 노출/숨김 + suffix 반영
    });

    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setError(String? v) {
    if (!mounted) return;
    setState(() => _errorText = v);
  }

  double _computeToastBottomPadding() {
    final media = MediaQuery.of(context);
    final screenH = media.size.height;

    double bottomPadding = media.padding.bottom + 18;

    final fabCtx = _fabKey.currentContext;
    if (fabCtx != null) {
      final render = fabCtx.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        final topLeft = render.localToGlobal(Offset.zero);
        final fabTopY = topLeft.dy;

        const gap = 14.0;
        bottomPadding = (screenH - fabTopY) + gap;

        bottomPadding += media.viewInsets.bottom;

        bottomPadding = bottomPadding.clamp(
          media.padding.bottom + 18,
          screenH * 0.75,
        );
      }
    }

    return bottomPadding;
  }

  void _showToastAboveFab(String message) {
    if (!mounted) return;
    AppToast.show(
      context,
      message,
      bottomPadding: _computeToastBottomPadding(),
    );
  }

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
      _showToastAboveFab('불러오지 못했어요');
    }
  }

  Future<void> _addKeyword() async {
    if (_saving) return;

    final keyword = _input;

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

      FocusScope.of(context).requestFocus(_focusNode);
    } catch (_) {
      if (!mounted) return;
      //_showToastAboveFab('저장에 실패했어요. 네트워크를 확인해주세요');
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

      // ✅ X 삭제 시 “저장했습니다.” 토스트 없음 (요구사항)
    } catch (_) {
      if (!mounted) return;
      //_showToastAboveFab('저장에 실패했어요. 네트워크를 확인해주세요');
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final underlineColor = p.outline.withOpacity(0.85);

    final selectionTheme = TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withOpacity(0.22),
      selectionHandleColor: p.accent,
    );

    final inputTextStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: p.ink,
      fontWeight: FontWeight.w500,
      fontSize: 18,
    );

    final hintStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: p.muted.withOpacity(0.65),
      fontWeight: FontWeight.w500,
      fontSize: 18,
    );

    return Scaffold(
      backgroundColor: p.bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _fabVisible
          ? Padding(
              key: _fabKey,
              padding: const EdgeInsets.only(right: 24, bottom: 24),
              child: GlassFab(
                onPressed: _addKeyword,
                enabled: _fabEnabled,
                color: p.accent,
                size: 72,
                iconWidget: Text(
                  '확인',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    // 라이트는 완전 흰색, 다크는 살짝 눌러서(너무 번쩍이지 않게)
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.86)
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
                lighten: 0.06,
                pressedScale: 0.98,
                floatEnabled: false,
              ),
            )
          : null,

      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: AppPageHeader(title: '', titleColor: p.ink, iconColor: p.ink),
      ),
      body: AppSafeArea(
        top: false,
        child: TextSelectionTheme(
          data: selectionTheme,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            children: [
              const SizedBox(height: 10),
              Text(
                '관심사',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              if (_loading)
                Text(
                  '불러오는 중…',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else ...[
                Text(
                  '키워드 기반으로 인사이트가 생성돼요.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !_saving,
                  cursorColor: p.accent,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addKeyword(), // ✅ 엔터 저장
                  maxLength: _maxKeywordLen,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_maxKeywordLen),
                  ],
                  style: inputTextStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: underlineColor, width: 1),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: underlineColor, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: p.accent.withOpacity(0.9),
                        width: 1,
                      ),
                    ),
                    hintText: '키워드 입력',
                    hintStyle: hintStyle,
                    counterText: '',
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    suffixIcon: (_controller.text.isEmpty)
                        ? null
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _saving
                                ? null
                                : () {
                                    _controller.clear();
                                    _focusNode.requestFocus();
                                    _setError(null);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Icon(
                                Icons.cancel_rounded,
                                size: 22,
                                color: _saving
                                    ? p.muted.withOpacity(0.35)
                                    : p.muted.withOpacity(0.55),
                              ),
                            ),
                          ),
                  ),
                ),

                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: p.muted,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                if (_keywords.isEmpty)
                  Text(
                    '아직 등록된 관심사가 없어요.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                        InterestBadge(
                          p: p,
                          text: k,
                          active: true,
                          onRemove: _saving ? null : () => _removeKeyword(k),
                        ),
                    ],
                  ),

                const SizedBox(height: 120), // ✅ FAB/Toast 공간
              ],
            ],
          ),
        ),
      ),
    );
  }
}

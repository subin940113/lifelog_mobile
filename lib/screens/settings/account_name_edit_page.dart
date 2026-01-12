import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/api/user_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/widgets/app_page_header.dart';
import 'package:lifelog_mobile/widgets/app_toast.dart';
import 'package:lifelog_mobile/widgets/glass_fab.dart';
import 'package:lifelog_mobile/widgets/app_safe_area.dart';

class AccountNameEditPage extends StatefulWidget {
  final Palette p;
  final String initialName;
  final VoidCallback? onLogout;

  const AccountNameEditPage({
    super.key,
    required this.p,
    required this.initialName,
    required this.onLogout,
  });

  @override
  State<AccountNameEditPage> createState() => _AccountNameEditPageState();
}

class _AccountNameEditPageState extends State<AccountNameEditPage> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const int _maxLen = 100;

  late final TextEditingController _c;
  final FocusNode _f = FocusNode();

  // ✅ FAB 실측용 키 (toast 위치 계산)
  final GlobalKey _saveFabKey = GlobalKey();

  bool _saving = false;
  late String _initialName;
  String? _errorText;

  Palette get p => widget.p;

  @override
  void initState() {
    super.initState();
    _initialName = widget.initialName;
    _c = TextEditingController(text: _initialName);
    _c.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  UserApiClient _userClient() {
    return UserApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _storage,
      onUnauthorized: () async {
        await _storage.deleteAll();
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
        widget.onLogout?.call();
      },
    );
  }

  String _normalize(String v) => v.trim();

  bool get _shouldShowSaveFab {
    final next = _normalize(_c.text);
    if (next.isEmpty) return false;
    return next != _normalize(_initialName);
  }

  // ✅ Interest/Record 방식: FAB 실제 위치 기준 토스트
  double _computeToastBottomPadding() {
    final media = MediaQuery.of(context);
    final screenH = media.size.height;

    double bottomPadding = media.padding.bottom + 18;

    final fabCtx = _saveFabKey.currentContext;
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

  void _showToast(String message) {
    if (!mounted) return;
    AppToast.show(
      context,
      message,
      bottomPadding: _computeToastBottomPadding(),
    );
  }

  Future<void> _save() async {
    if (_saving) return;

    final next = _normalize(_c.text);

    if (next.isEmpty) {
      setState(() => _errorText = '계정명을 입력해주세요.');
      return;
    }

    if (next == _normalize(_initialName)) {
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(null);
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      final updated = await _userClient().updateMe(displayName: next);

      await _storage.write(key: 'accountName', value: updated.displayName);

      if (!mounted) return;

      setState(() {
        _initialName = updated.displayName;
        _saving = false;
        _errorText = null;
      });

      if (_c.text != updated.displayName) {
        _c.text = updated.displayName;
        _c.selection = TextSelection.fromPosition(
          TextPosition(offset: _c.text.length),
        );
      }

      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(updated.displayName);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = '저장에 실패했어요. 네트워크를 확인해주세요.';
      });
      //_showToast('저장 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    final underlineColor = p.outline.withOpacity(0.85);

    final selectionTheme = TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withOpacity(0.22),
      selectionHandleColor: p.accent,
    );

    return Scaffold(
      backgroundColor: p.bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // ✅ Scaffold FAB 슬롯로 이동 + AnimatedSwitcher 유지
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, anim) {
          final scale = Tween<double>(
            begin: 0.94,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: _shouldShowSaveFab
            ? SizedBox(
                key: _saveFabKey, // ✅ 토스트 위치 실측용
                child: SafeArea(
                  minimum: const EdgeInsets.only(bottom: 24),
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: GlassFab(
                      onPressed: _save,
                      enabled: !_saving,
                      color: p.accent,
                      size: 72,
                      iconWidget: SoftCheckIcon(
                        size: 30,
                        color: Colors.white.withOpacity(_saving ? 0.55 : 1.0),
                        stroke: 4.6,
                        rotate: -0.1,
                      ),
                      lighten: 0.06,
                      pressedScale: 0.98,
                      floatEnabled: false,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('save-fab-hidden')),
      ),

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
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              const SizedBox(height: 20),
              Text(
                '계정명 설정',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '설정한 계정명은 앱에서 표시되는 이름이에요.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: p.muted,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _c,
                focusNode: _f,
                enabled: !_saving,
                autofocus: true,
                cursorColor: p.accent,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                maxLength: _maxLen,
                inputFormatters: [LengthLimitingTextInputFormatter(_maxLen)],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
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
                  hintText: '계정명 입력',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: p.muted.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                  counterText: '',
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: (_c.text.isEmpty)
                      ? null
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _saving
                              ? null
                              : () {
                                  _c.clear();
                                  _f.requestFocus();
                                  if (!mounted) return;
                                  setState(() => _errorText = null);
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

              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${_c.text.length}/$_maxLen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: p.muted.withOpacity(0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],

              const SizedBox(height: 120), // ✅ FAB 공간
            ],
          ),
        ),
      ),
    );
  }
}

// lib/screens/settings/account_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:lifelog_mobile/api/user_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'widgets/settings_page_header.dart';

class AccountSettingsPage extends StatefulWidget {
  final Palette p;
  final VoidCallback? onLogout;

  const AccountSettingsPage({
    super.key,
    required this.p,
    required this.onLogout,
  });

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  static const _storage = FlutterSecureStorage();

  late Future<UserMeResponse> _meFuture;
  bool _savingName = false;

  /// ✅ “저장 후에도 페이지는 유지”하면서,
  /// 뒤로갈 때 SettingsHome이 최신 이름을 받을 수 있도록 보관.
  String? _latestDisplayName;

  Palette get p => widget.p;

  @override
  void initState() {
    super.initState();
    _meFuture = _fetchMe();
  }

  UserApiClient _userClient() {
    return UserApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _storage,
      onUnauthorized: () async {
        await _storage.deleteAll();
        if (mounted) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
        widget.onLogout?.call();
      },
    );
  }

  Future<UserMeResponse> _fetchMe() async {
    final me = await _userClient().getMe();
    _latestDisplayName = me.displayName;
    return me;
  }

  String _fmtIsoDate(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  // ✅ 로그아웃/삭제 Confirm (CupertinoActionSheet or Material BottomSheet)
  Future<bool> _showConfirmSheet(
    BuildContext context, {
    required String message,
    required String actionText,
    required Color actionColor,
  }) async {
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    if (isCupertino) {
      final isDestructive = actionColor.value == p.danger.value;

      final result = await showCupertinoModalPopup<bool>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.12),
        builder: (sheetContext) {
          return CupertinoActionSheet(
            message: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: p.ink.withOpacity(0.85),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                isDestructiveAction: isDestructive,
                child: Text(
                  actionText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDestructive ? p.danger : p.accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(false),
              child: Text(
                '취소',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: p.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          );
        },
      );

      return result == true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: false,
      barrierColor: Colors.black.withOpacity(0.18),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                children: [
                  Center(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.ink.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BottomSheetAction(
                    label: actionText,
                    color: actionColor,
                    onTap: () => Navigator.of(sheetContext).pop(true),
                  ),
                  const SizedBox(height: 6),
                  _BottomSheetAction(
                    label: '취소',
                    color: p.muted,
                    onTap: () => Navigator.of(sheetContext).pop(false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result == true;
  }

  Future<String?> _showEditDisplayNameSheet(
    BuildContext context, {
    required String initial,
  }) async {
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    final controller = TextEditingController(text: initial);
    String sanitize(String v) => v.trim();

    if (isCupertino) {
      return showCupertinoModalPopup<String?>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.18),
        builder: (sheetContext) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.outline.withOpacity(0.10)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '계정명 변경',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: p.ink,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.outline.withOpacity(0.12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          // Keep iOS tint consistent (clear button, etc.)
                          primaryColor: p.accent,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: TextSelectionTheme(
                            data: TextSelectionThemeData(
                              cursorColor: p.accent,
                              selectionColor: p.accent.withOpacity(0.22),
                              selectionHandleColor: p.accent,
                            ),
                            child: TextField(
                              controller: controller,
                              autofocus: true,
                              maxLength: 50,
                              cursorColor: p.accent,
                              textInputAction: TextInputAction.done,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: p.ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                              decoration: InputDecoration(
                                hintText: '계정명',
                                hintStyle: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: p.muted.withOpacity(0.75),
                                      fontWeight: FontWeight.w500,
                                    ),
                                counterText: '',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (_) {
                                final v = sanitize(controller.text);
                                Navigator.of(
                                  sheetContext,
                                ).pop(v.isEmpty ? null : v);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: p.outline.withOpacity(0.10),
                    ),
                    const SizedBox(height: 6),
                    // ✅ 하단 좌우 나란히
                    Row(
                      children: [
                        Expanded(
                          child: _SheetTextAction(
                            label: '취소',
                            color: p.muted,
                            onTap: () => Navigator.of(sheetContext).pop(null),
                          ),
                        ),
                        Expanded(
                          child: _SheetTextAction(
                            label: '저장',
                            color: p.accent,
                            onTap: () {
                              final v = sanitize(controller.text);
                              Navigator.of(
                                sheetContext,
                              ).pop(v.isEmpty ? null : v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Material (Android)
    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: p.bg,
          surfaceTintColor: Colors.transparent,
          title: Text(
            '계정명 변경',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: p.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextSelectionTheme(
            data: TextSelectionThemeData(
              cursorColor: p.accent,
              selectionColor: p.accent.withOpacity(0.22),
              selectionHandleColor: p.accent,
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 50,
              cursorColor: p.accent,
              decoration: InputDecoration(
                hintText: '계정명',
                counterText: '',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: p.outline.withOpacity(0.18)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: p.accent.withOpacity(0.55)),
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: p.ink,
                fontWeight: FontWeight.w500,
              ),
              onSubmitted: (_) {
                final v = sanitize(controller.text);
                Navigator.of(ctx).pop(v.isEmpty ? null : v);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                '취소',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: p.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final v = sanitize(controller.text);
                Navigator.of(ctx).pop(v.isEmpty ? null : v);
              },
              child: Text(
                '저장',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: p.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editDisplayName(UserMeResponse me) async {
    if (_savingName) return;

    final initial = me.displayName.trim();

    final next = await _showEditDisplayNameSheet(context, initial: initial);

    if (!mounted) return;
    if (next == null) return;

    final v = next.trim();
    if (v.isEmpty || v == me.displayName) return;

    setState(() => _savingName = true);

    try {
      final updated = await _userClient().updateMe(displayName: v);

      // ✅ Settings 헤더용 로컬 캐시 갱신
      await _storage.write(key: 'accountName', value: updated.displayName);

      // ✅ 이 페이지는 유지. 대신, 뒤로갈 때 최신 값 전달용으로 보관.
      _latestDisplayName = updated.displayName;

      if (!mounted) return;
      setState(() {
        _meFuture = Future.value(updated);
        _savingName = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingName = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '계정명 저장에 실패했어요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: p.ink.withOpacity(0.90),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final ok = await _showConfirmSheet(
      context,
      message: '정말 로그아웃할까요?',
      actionText: '로그아웃',
      actionColor: p.accent,
    );
    if (!ok) return;

    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'accountName');
    await _storage.delete(key: 'isNewUser');

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    widget.onLogout?.call();
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final ok = await _showConfirmSheet(
      context,
      message: '계정을 삭제할까요?\n삭제 후에는 복구할 수 없어요.',
      actionText: '삭제',
      actionColor: p.danger,
    );
    if (!ok) return;

    // 서버 삭제 로직은 기존 흐름 유지(원하면 여기 연결)
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'accountName');
    await _storage.delete(key: 'isNewUser');

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ 뒤로 갈 때만 최신 displayName을 result로 넘긴다.
      onWillPop: () async {
        Navigator.of(context).pop(_latestDisplayName);
        return false;
      },
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  SettingsPageHeader(
                    title: '계정',
                    titleColor: p.ink,
                    iconColor: p.ink,
                  ),
                  Expanded(
                    child: FutureBuilder<UserMeResponse>(
                      future: _meFuture,
                      builder: (context, snapshot) {
                        final loading =
                            snapshot.connectionState == ConnectionState.waiting;

                        var displayName = '—';
                        var joinedAt = '—';
                        var lastLoginAt = '—';

                        UserMeResponse? me;
                        if (snapshot.hasData) {
                          me = snapshot.data!;
                          displayName = me.displayName.isNotEmpty
                              ? me.displayName
                              : '—';
                          joinedAt = _fmtIsoDate(me.createdAt);
                          lastLoginAt = _fmtIsoDate(me.lastLoginAt);

                          // 혹시 서버에서 다시 내려온 값이 있으면 최신값 갱신
                          _latestDisplayName = me.displayName;
                        }

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
                          children: [
                            _EditableInfoRow(
                              label: '계정명',
                              value: displayName,
                              p: p,
                              enabled: !_savingName && me != null,
                              onEdit: me == null
                                  ? null
                                  : () => _editDisplayName(me!),
                              actionLabel: '편집',
                            ),
                            _InfoRow(label: '가입', value: joinedAt, p: p),
                            _InfoRow(label: '최근 로그인', value: lastLoginAt, p: p),
                            if (snapshot.hasError) ...[
                              const SizedBox(height: 10),
                              Text(
                                '계정 정보를 불러오지 못했어요.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: p.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ] else if (loading) ...[
                              const SizedBox(height: 10),
                              Text(
                                '불러오는 중…',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: p.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  decoration: BoxDecoration(color: p.bg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onLogout != null)
                        _BottomTextAction(
                          label: '로그아웃',
                          color: p.ink,
                          onTap: () => _handleLogout(context),
                        ),
                      const SizedBox(height: 14),
                      _BottomTextAction(
                        label: '계정 삭제',
                        color: p.danger,
                        onTap: () => _handleDeleteAccount(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Palette p;

  const _InfoRow({required this.label, required this.value, required this.p});

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.outline.withOpacity(0.9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: baseStyle?.copyWith(
                color: p.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: baseStyle?.copyWith(
                color: p.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Palette p;
  final bool enabled;
  final VoidCallback? onEdit;
  final String actionLabel;

  const _EditableInfoRow({
    required this.label,
    required this.value,
    required this.p,
    required this.enabled,
    required this.onEdit,
    this.actionLabel = '편집',
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge;

    const labelWidth = 64.0;
    const actionWidth = 46.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.outline.withOpacity(0.9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: baseStyle?.copyWith(
                color: p.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),

          /// ✅ “값 + 편집”을 우측 그룹으로 묶고,
          /// 값↔편집 사이 간격을 고정하여 값이 짧아도 과한 공백이 생기지 않게.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: baseStyle?.copyWith(
                      color: p.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: actionWidth,
                  child: GestureDetector(
                    onTap: enabled ? onEdit : null,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          actionLabel,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: enabled
                                    ? p.accent.withOpacity(0.92)
                                    : p.muted.withOpacity(0.45),
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomTextAction extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomTextAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_BottomTextAction> createState() => _BottomTextActionState();
}

class _BottomTextActionState extends State<_BottomTextAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final opacity = _pressed ? 0.55 : 1.0;

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: widget.color,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetAction extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_BottomSheetAction> createState() => _BottomSheetActionState();
}

class _BottomSheetActionState extends State<_BottomSheetAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final opacity = _pressed ? 0.55 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: widget.color,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTextAction extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetTextAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SheetTextAction> createState() => _SheetTextActionState();
}

class _SheetTextActionState extends State<_SheetTextAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final opacity = _pressed ? 0.55 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: widget.color,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

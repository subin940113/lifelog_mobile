import 'package:flutter/material.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifelog_mobile/api/auth_api_client.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'widgets/settings_page_header.dart';
import 'package:lifelog_mobile/config/api_config.dart';

import 'package:flutter/cupertino.dart';

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

  late Future<_UserMe> _meFuture;

  Palette get p => widget.p;

  @override
  void initState() {
    super.initState();
    _meFuture = _fetchMe();
  }

  Future<_UserMe> _fetchMe() async {
    final client = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _storage,
      onUnauthorized: () async {
        await _storage.deleteAll();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        widget.onLogout?.call();
      },
    );

    final map = await client.getJson('/api/users/me');
    return _UserMe.fromJson(map);
  }

  String _fmtInstant(InstantLike instant) {
    final dt = DateTime.parse(instant.value).toLocal();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  Future<bool> _showActionSheet(
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

    // Material (Android etc.): minimal bottom sheet, no heavy buttons.
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

  Future<void> _handleLogout(BuildContext context) async {
    final ok = await _showActionSheet(
      context,
      message: '정말 로그아웃할까요?',
      actionText: '로그아웃',
      actionColor: p.accent,
    );

    if (!ok) return;

    // Best-effort server logout (revoke refresh token). Even if it fails,
    // we still clear local tokens to reflect immediate logout UX.
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final client = AuthApiClient(
          baseUrl: ApiConfig.baseUrl,
          storage: _storage,
          onUnauthorized: () async {
          await _storage.deleteAll();
          widget.onLogout?.call();
        },
        );
        await client.logout(refreshToken: refreshToken, allDevices: false);
      }
    } catch (_) {
      // Ignore server/network errors; local logout should still proceed.
    }

    // Clear local session
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'accountName');
    await _storage.delete(key: 'isNewUser');

    // ✅ 화면이 “로그아웃 됐다”는 걸 즉시 보이게: Settings/Account 스택부터 닫기
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    final cb = widget.onLogout;
    if (cb != null) cb();
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final ok = await _showActionSheet(
        context,
        message: '계정을 삭제할까요?\n삭제 후에는 복구할 수 없어요.',
        actionText: '삭제',
        actionColor: p.danger,
    );

    if (!ok) return;

    try {
        final client = AuthApiClient(
        baseUrl: ApiConfig.baseUrl,
        storage: _storage,
        onUnauthorized: () async {
            await _storage.deleteAll();
            final cb = widget.onLogout;
            if (cb != null) cb();
        },
        );

        // ✅ 서버 계정 삭제 (DELETE /api/users/me)
        await client.deleteAccount();
    } catch (_) {
        // 서버/네트워크 실패해도 UX는 계속 진행
    }

    // ✅ 로컬 세션은 무조건 정리
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'accountName');
    await _storage.delete(key: 'isNewUser');

    if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
    }

    final cb = widget.onLogout;
    if (cb != null) cb();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: FutureBuilder<_UserMe>(
                    future: _meFuture,
                    builder: (context, snapshot) {
                      final loading = snapshot.connectionState == ConnectionState.waiting;

                      // Defaults (em dash) – replaced when API data is available
                      var displayName = '—';
                      var joinedAt = '—';
                      var lastLoginAt = '—';

                      if (snapshot.hasData) {
                        final me = snapshot.data!;

                        // API: createdAt, lastLoginAt
                        joinedAt = _fmtInstant(InstantLike(me.createdAt));
                        lastLoginAt = _fmtInstant(InstantLike(me.lastLoginAt));

                        displayName = me.displayName?.isNotEmpty == true ? me.displayName! : '—';
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                        children: [
                          _InfoRow(label: '계정명', value: displayName, p: p),
                          _InfoRow(label: '가입', value: joinedAt, p: p),
                          _InfoRow(label: '최근 로그인', value: lastLoginAt, p: p),

                          if (snapshot.hasError) ...[
                            const SizedBox(height: 10),
                            Text(
                              '계정 정보를 불러오지 못했어요.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: p.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ] else if (loading) ...[
                            const SizedBox(height: 10),
                            Text(
                              '불러오는 중…',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                decoration: BoxDecoration(
                  color: p.bg,
                ),
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
    );
  }
}

/// Small helper to keep the date formatting code explicit.
class InstantLike {
  final String value;
  InstantLike(this.value);
}

class _UserMe {
  final int id;
  final String? displayName;
  final String createdAt;
  final String lastLoginAt;

  _UserMe({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory _UserMe.fromJson(Map<String, dynamic> json) {
    return _UserMe(
      id: (json['id'] as num).toInt(),
      displayName: json['displayName'] as String?,
      createdAt: json['createdAt'] as String,
      lastLoginAt: json['lastLoginAt'] as String,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Palette p;
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Palette p;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: p.outline.withOpacity(0.9)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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

class _ActionRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Palette p;
  final Color color;

  const _ActionRow({
    required this.title,
    required this.onTap,
    required this.p,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge;
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: p.outline.withOpacity(0.9)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: baseStyle?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal bottom action (centered text, no box).
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

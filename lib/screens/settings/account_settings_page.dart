import 'package:flutter/material.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import 'widgets/settings_page_header.dart';
import 'widgets/settings_row.dart';

class AccountSettingsPage extends StatelessWidget {
  final Palette p;
  final VoidCallback? onLogout;

  const AccountSettingsPage({
    super.key,
    required this.p,
    required this.onLogout,
  });

  Future<bool> _showActionSheet(
    BuildContext context, {
    required String message,
    required String actionText,
    required Color actionColor,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: false,
      barrierColor: Colors.black.withOpacity(0.28),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: p.bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.outline.withOpacity(0.9)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: actionColor,
                      foregroundColor: p.bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      actionText,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: p.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
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

    // ✅ 화면이 “로그아웃 됐다”는 걸 즉시 보이게: Settings/Account 스택부터 닫기
    Navigator.of(context).popUntil((route) => route.isFirst);

    final cb = onLogout;
    if (cb != null) cb();
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final ok = await _showActionSheet(
      context,
      message: '계정을 삭제할까요?\n삭제 후에는 복구할 수 없어요.',
      actionText: '삭제',
      actionColor: p.danger, // ✅ 팔레트 danger
    );

    if (!ok) return;

    // TODO: 계정 삭제 API 연동 후 구현
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 계정 정보는 /api/users/me 연동 후 주입
    const email = '—';
    const provider = '—';
    const joinedAt = '—';
    const lastLoginAt = '—';

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            SettingsPageHeader(
              title: '계정',
              titleColor: p.ink,
              iconColor: p.ink,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                children: [
                  _SectionLabel(text: '기본 정보', p: p),
                  const SizedBox(height: 6),
                  _InfoRow(label: '이메일', value: email, p: p),
                  _InfoRow(label: '연결된 로그인', value: provider, p: p),
                  _InfoRow(label: '최초 가입 날짜', value: joinedAt, p: p),
                  _InfoRow(label: '최근 로그인 날짜', value: lastLoginAt, p: p),

                  const SizedBox(height: 18),
                  _SectionLabel(text: '계정', p: p),
                  const SizedBox(height: 6),

                  if (onLogout != null) ...[
                    SettingsRow(
                      title: '로그아웃',
                      onTap: () => _handleLogout(context),
                      p: p,
                      showChevron: false,
                    ),
                    const SizedBox(height: 6),
                  ],

                  SettingsRow(
                    title: '계정 삭제',
                    onTap: () => _handleDeleteAccount(context),
                    p: p,
                    showChevron: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    return Container(
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
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
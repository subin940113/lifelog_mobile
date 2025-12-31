import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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

  // Use a compile-time env var if provided; otherwise default to localhost.
  // You can pass `--dart-define=API_BASE_URL=http://<host>:8080` at build/run time.
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  late Future<_UserMe> _meFuture;

  Palette get p => widget.p;

  @override
  void initState() {
    super.initState();
    _meFuture = _fetchMe();
  }

  Future<_UserMe> _fetchMe() async {
    final accessToken = await _storage.read(key: 'accessToken');
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('accessToken이 없습니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse('$_apiBaseUrl/api/users/me');
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('계정 정보를 불러오지 못했습니다. (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return _UserMe.fromJson(decoded);
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

    final cb = widget.onLogout;
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

                    // Not provided by /api/users/me (per current contract)
                    // Keep as '—' until backend adds them.
                    // email = me.email ?? '—';
                    // provider = me.provider ?? '—';

                    // If you want to show displayName somewhere later, it is available:
                    // me.displayName
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    children: [
                      _SectionLabel(text: '기본 정보', p: p),
                      const SizedBox(height: 6),
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

                      const SizedBox(height: 18),
                      _SectionLabel(text: '계정', p: p),
                      const SizedBox(height: 6),

                      if (widget.onLogout != null)
                        _ActionRow(
                          title: '로그아웃',
                          onTap: () => _handleLogout(context),
                          p: p,
                          color: p.ink,
                        ),

                      _ActionRow(
                        title: '계정삭제',
                        onTap: () => _handleDeleteAccount(context),
                        p: p,
                        color: p.danger,
                      ),
                    ],
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
          const SizedBox(width: 12),
          Flexible(
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
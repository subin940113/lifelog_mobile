import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/push_api_client.dart';

class PushTokenManager {
  static const _kStorageKey = 'push.fcmToken';

  final FlutterSecureStorage storage;
  final AuthApiClient authApi;

  late final PushApiClient _pushApi;
  bool _tokenRefreshListenerBound = false;

  PushTokenManager({required this.storage, required this.authApi}) {
    _pushApi = PushApiClient(authApi);
  }

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// 앱이 부팅될 때(권한 요청 이후) 토큰을 저장만 해둔다.
  Future<void> persistLatestToken() async {
    final messaging = FirebaseMessaging.instance;

    // APNs token 확보를 먼저 시도 (iOS에서 안정성 도움)
    if (Platform.isIOS) {
      try {
        await messaging.getAPNSToken();
      } catch (_) {}
    }

    final fcmToken = await messaging.getToken();
    if (fcmToken == null || fcmToken.trim().isEmpty) return;

    await storage.write(key: _kStorageKey, value: fcmToken.trim());
  }

  /// 로그인된 상태에서 서버에 업서트.
  /// - AppShell에서 _loggedIn = true 된 직후 호출하면 가장 안전함.
  Future<void> registerIfPossible() async {
    final token = await storage.read(key: _kStorageKey);
    if (token == null || token.trim().isEmpty) return;

    try {
      await _pushApi.registerToken(token: token.trim(), platform: _platform);
      debugPrint('[PUSH] token registered');
    } catch (e) {
      // 네트워크/인증 문제면 조용히 실패. 다음 기회에 재시도하면 됨.
      debugPrint('[PUSH] register failed: $e');
    }

    _bindTokenRefreshListenerOnce();
  }

  /// 로그아웃 시 서버에서 토큰 제거(선택이지만 권장)
  Future<void> unregisterIfPossible() async {
    final token = await storage.read(key: _kStorageKey);
    if (token == null || token.trim().isEmpty) return;

    // ✅ accessToken 없으면(이미 로그아웃/토큰 삭제됨) 서버 삭제는 스킵
    final accessToken = await storage.read(key: 'accessToken');
    if (accessToken == null || accessToken.trim().isEmpty) {
      debugPrint('[PUSH] skip delete (no accessToken)');
      return;
    }

    try {
      await _pushApi.deleteToken(token: token.trim());
      debugPrint('[PUSH] token deleted');
    } catch (e) {
      debugPrint('[PUSH] delete failed: $e');
    }
  }

  void _bindTokenRefreshListenerOnce() {
    if (_tokenRefreshListenerBound) return;
    _tokenRefreshListenerBound = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final t = newToken.trim();
      if (t.isEmpty) return;

      // 로컬 저장 업데이트
      await storage.write(key: _kStorageKey, value: t);

      // 로그인 상태에서만 서버 업서트가 성공할 것.
      try {
        await _pushApi.registerToken(token: t, platform: _platform);
        debugPrint('[PUSH] token refreshed + registered');
      } catch (e) {
        debugPrint('[PUSH] refresh register failed: $e');
      }
    });
  }
}

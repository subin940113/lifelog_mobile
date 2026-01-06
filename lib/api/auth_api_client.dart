import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthLoginResult {
  final String accessToken;
  final String refreshToken;
  final String displayName;
  final bool isNewUser;

  const AuthLoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.displayName,
    required this.isNewUser,
  });
}

/// Shared authenticated API client.
///
/// - Adds Authorization header automatically
/// - On 401/403: refresh once (global lock) then retries once
/// - Persists rotated access/refresh tokens
class AuthApiClient {
  final String baseUrl;
  final FlutterSecureStorage storage;
  final VoidCallback? onUnauthorized;

  AuthApiClient({
    required this.baseUrl,
    required this.storage,
    this.onUnauthorized,
  });

  static Future<void>? _refreshInFlight;

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('$baseUrl$normalized');

    if (queryParameters == null || queryParameters.isEmpty) return base;

    // 기존 base의 쿼리와 병합
    final merged = <String, String>{
      ...base.queryParameters,
      ...queryParameters,
    };
    return base.replace(queryParameters: merged);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final res = await _sendWithRefresh(() async {
      final token = await _requireAccessToken();

      final uri = _uri(path).replace(
        queryParameters: (queryParameters == null || queryParameters.isEmpty)
            ? null
            : queryParameters,
      );

      return http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    });

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('서버 응답 JSON이 객체가 아닙니다: ${res.body}');
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final res = await _sendWithRefresh(() async {
      final token = await _requireAccessToken();
      return http.post(
        _uri(path),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );
    });

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('서버 응답 JSON이 객체가 아닙니다: ${res.body}');
  }

  Future<Map<String, dynamic>> postJsonUnauthenticated(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      _uri(path),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API 실패 (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('서버 응답 JSON이 객체가 아닙니다: ${res.body}');
  }

  /// Logout by revoking the refresh token on the server.
  ///
  /// Server is expected to return 204 No Content (or any 2xx).
  Future<void> logout({
    required String refreshToken,
    bool allDevices = false,
  }) async {
    final res = await http.post(
      _uri('/api/auth/logout'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'refreshToken': refreshToken,
        'allDevices': allDevices,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('로그아웃 실패 (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> deleteAccount() async {
    final res = await _sendWithRefresh(() async {
      final token = await _requireAccessToken();
      return http.delete(
        _uri('/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('계정 삭제 실패 (${res.statusCode}): ${res.body}');
    }
  }

  Future<AuthLoginResult> loginWithGoogleIdToken(String idToken) async {
    final map = await postJsonUnauthenticated(
      '/api/auth/oauth/google',
      {'idToken': idToken},
    );

    final accessToken = map['accessToken'] as String?;
    final refreshToken = map['refreshToken'] as String?;
    final displayName = map['displayName'] as String?;
    final isNewUser = map['isNewUser'] as bool?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('서버 응답에 accessToken이 없습니다: ${jsonEncode(map)}');
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('서버 응답에 refreshToken이 없습니다: ${jsonEncode(map)}');
    }

    final safeName = (displayName != null && displayName.trim().isNotEmpty) ? displayName.trim() : '계정';

    return AuthLoginResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      displayName: safeName,
      isNewUser: isNewUser ?? false,
    );
  }

  Future<String> _requireAccessToken() async {
    final accessToken = await storage.read(key: 'accessToken');
    if (accessToken == null || accessToken.isEmpty) {
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
      throw Exception('accessToken이 없습니다. 다시 로그인해주세요.');
    }
    return accessToken;
  }

  Future<String> _requireRefreshToken() async {
    final refreshToken = await storage.read(key: 'refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('refreshToken이 없습니다. 다시 로그인해주세요.');
    }
    return refreshToken;
  }

  Future<http.Response> _sendWithRefresh(Future<http.Response> Function() request) async {
    var res = await request();

    if (res.statusCode == 401 || res.statusCode == 403) {
      await _refreshOnceLocked();
      res = await request();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API 실패 (${res.statusCode}): ${res.body}');
    }

    return res;
  }

  Future<void> _refreshOnceLocked() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final refreshFuture = _refreshTokens();
    _refreshInFlight = refreshFuture;

    try {
      await refreshFuture;
    } catch (e) {
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
      rethrow;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<void> _refreshTokens() async {
    final refreshToken = await _requireRefreshToken();

    final res = await http.post(
      _uri('/api/auth/refresh'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('토큰 갱신 실패 (${res.statusCode}): ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final newAccessToken = map['accessToken'] as String?;
    final newRefreshToken = map['refreshToken'] as String?;

    if (newAccessToken == null || newAccessToken.isEmpty) {
      throw Exception('토큰 갱신 응답에 accessToken이 없습니다: ${res.body}');
    }
    if (newRefreshToken == null || newRefreshToken.isEmpty) {
      throw Exception('토큰 갱신 응답에 refreshToken이 없습니다: ${res.body}');
    }

    await storage.write(key: 'accessToken', value: newAccessToken);
    await storage.write(key: 'refreshToken', value: newRefreshToken);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final res = await _sendWithRefresh(() async {
      final token = await _requireAccessToken();
      return http.delete(
        _uri(path),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    });

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('서버 응답 JSON이 객체가 아닙니다: ${res.body}');
  }
}
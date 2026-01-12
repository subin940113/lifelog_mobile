import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifelog_mobile/api/auth_api_client.dart';

class UserMeResponse {
  final int id;
  final String displayName;
  final String createdAt; // ISO string
  final String lastLoginAt; // ISO string

  const UserMeResponse({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserMeResponse.fromJson(Map<String, dynamic> json) {
    return UserMeResponse(
      id: (json['id'] as num).toInt(),
      displayName: (json['displayName'] as String?) ?? '계정',
      createdAt: json['createdAt'] as String,
      lastLoginAt: json['lastLoginAt'] as String,
    );
  }
}

class UserApiClient {
  final AuthApiClient _auth;

  UserApiClient({
    required String baseUrl,
    required FlutterSecureStorage storage,
    void Function()? onUnauthorized,
  }) : _auth = AuthApiClient(
         baseUrl: baseUrl,
         storage: storage,
         onUnauthorized: onUnauthorized,
       );

  Future<UserMeResponse> getMe() async {
    final map = await _auth.getJson('/api/users/me');
    return UserMeResponse.fromJson(map);
  }

  /// PATCH /api/users/me
  /// body: { displayName: "..." }
  Future<UserMeResponse> updateMe({String? displayName}) async {
    final map = await _auth.patchJson('/api/users/me', {
      if (displayName != null) 'displayName': displayName,
    });
    return UserMeResponse.fromJson(map);
  }

  Future<void> deleteMe() async {
    await _auth.deleteJson('/api/users/me');
  }
}

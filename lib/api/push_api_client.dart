import 'package:lifelog_mobile/api/auth_api_client.dart';

class PushSettings {
  final bool enabled;

  const PushSettings({required this.enabled});

  factory PushSettings.fromJson(Map<String, dynamic> json) {
    return PushSettings(enabled: json['enabled'] == true);
  }

  Map<String, dynamic> toJson() => {'enabled': enabled};
}

class PushApiClient {
  final AuthApiClient _api;
  PushApiClient(this._api);

  /// POST /api/push/token
  /// body: { token: "...", platform: "ios" | "android" }
  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    final t = token.trim();
    if (t.isEmpty) return;

    await _api.postJson('/api/push/token', {'token': t, 'platform': platform});
  }

  /// DELETE /api/push/token?token=...
  Future<void> deleteToken({required String token}) async {
    final t = token.trim();
    if (t.isEmpty) return;

    await _api.deleteJson('/api/push/token?token=$t');
  }

  /// GET /api/push/settings
  Future<PushSettings> getSettings() async {
    final json = await _api.getJson('/api/push/settings');
    return PushSettings.fromJson(json);
  }

  /// PUT /api/push/settings
  /// body: { enabled: boolean }
  Future<PushSettings> setEnabled(bool enabled) async {
    final json = await _api.putJson('/api/push/settings', {'enabled': enabled});
    return PushSettings.fromJson(json);
  }
}

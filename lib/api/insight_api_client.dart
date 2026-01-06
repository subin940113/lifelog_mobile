import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/models/ai_insight_item.dart';

class InsightSettings {
  final bool enabled;

  const InsightSettings({required this.enabled});

  factory InsightSettings.fromJson(Map<String, dynamic> m) {
    return InsightSettings(enabled: m['enabled'] == true);
  }
}

class InsightApiClient {
  final AuthApiClient _api;
  InsightApiClient(this._api);

  /// GET /api/insights?limit=20
  /// {
  ///   "insights":[
  ///     {"kind":"PATTERN","title":"...","body":"...","evidence":"...","keyword":"고양이"}
  ///   ]
  /// }
  Future<List<AiInsightItem>> getInsights({int limit = 20}) async {
    final safeLimit = limit.clamp(0, 50);
    final map = await _api.getJson('/api/insights?limit=$safeLimit');

    final list = (map['insights'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((m) => AiInsightItem.fromJson(m.cast<String, dynamic>()))
        .where((x) => x.title.trim().isNotEmpty && x.body.trim().isNotEmpty)
        .toList();
  }

  /// GET /api/insights/settings
  /// { "enabled": true/false }
  Future<InsightSettings> getSettings() async {
    final map = await _api.getJson('/api/insights/settings');
    return InsightSettings.fromJson(map);
  }

  /// POST /api/insights/settings
  /// body: { "enabled": true/false }
  /// res:  { "enabled": true/false }
  Future<InsightSettings> setEnabled(bool enabled) async {
    final map = await _api.postJson(
      '/api/insights/settings',
      {'enabled': enabled},
    );
    return InsightSettings.fromJson(map);
  }
}
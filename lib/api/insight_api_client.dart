import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/models/ai_insight_item.dart';

class InsightSettings {
  final bool enabled;

  const InsightSettings({required this.enabled});

  factory InsightSettings.fromJson(Map<String, dynamic> m) {
    return InsightSettings(enabled: m['enabled'] == true);
  }
}

/// Cursor paging response
class InsightsPage {
  final List<AiInsightItem> items;
  final String? nextCursor;

  const InsightsPage({
    required this.items,
    required this.nextCursor,
  });

  bool get hasMore => nextCursor != null && nextCursor!.trim().isNotEmpty;
}

class InsightApiClient {
  final AuthApiClient _api;
  InsightApiClient(this._api);

  /// GET /api/insights?limit=20&cursor=...
  /// {
  ///   "insights":[ { ... } ],
  ///   "nextCursor": "..."
  /// }
  Future<InsightsPage> getInsightsPage({
    int limit = 20,
    String? cursor,
  }) async {
    final safeLimit = limit.clamp(1, 50);

    final qs = StringBuffer('/api/insights?limit=$safeLimit');
    if (cursor != null && cursor.trim().isNotEmpty) {
      qs.write('&cursor=${Uri.encodeComponent(cursor)}');
    }

    final map = await _api.getJson(qs.toString());

    final list = (map['insights'] as List?) ?? const [];
    final items = list
        .whereType<Map>()
        .map((m) => AiInsightItem.fromJson(m.cast<String, dynamic>()))
        .where((x) => x.title.trim().isNotEmpty && x.body.trim().isNotEmpty)
        .toList();

    final nextCursor = (map['nextCursor'] as String?)?.trim();
    return InsightsPage(
      items: items,
      nextCursor: (nextCursor != null && nextCursor.isNotEmpty) ? nextCursor : null,
    );
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
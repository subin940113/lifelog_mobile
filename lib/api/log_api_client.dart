import 'package:lifelog_mobile/api/auth_api_client.dart';

class LogApiClient {
  final AuthApiClient _api;

  LogApiClient(this._api);

  /// POST /api/logs
  Future<CreateLogResult> createLog({required String content}) async {
    final res = await _api.postJson('/api/logs', {'content': content});

    final logId = res['logId'];
    if (logId is! int) {
      throw Exception('logId가 올바르지 않습니다: $res');
    }

    return CreateLogResult(logId: logId);
  }

  /// GET /api/logs?limit=50&cursor=...
  /// {
  ///   "items": [
  ///     {
  ///       "logId": 1,
  ///       "createdAt": "2026-01-05T10:55:00Z",
  ///       "dateLabel": "2026.01.05",
  ///       "timeLabel": "19:55",
  ///       "preview": "..."
  ///     }
  ///   ],
  ///   "nextCursor": "..."
  /// }
  Future<LogsPageResponse> getAllLogs({int limit = 50, String? cursor}) async {
    final safeLimit = limit.clamp(1, 100);

    final qp = <String, String>{
      'limit': '$safeLimit',
      if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
    };

    // AuthApiClient에는 query parameter 지원이 없으므로, URL에 직접 붙입니다.
    final uri = Uri(path: '/api/logs', queryParameters: qp).toString();

    final map = await _api.getJson(uri);

    final dynamic rawList = map['items'] ?? const [];
    final List<Map<String, dynamic>> items = (rawList is List)
        ? rawList
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];

    final nextCursor = (map['nextCursor'] as String?)?.trim();
    return LogsPageResponse(
      items: items,
      nextCursor: (nextCursor == null || nextCursor.isEmpty)
          ? null
          : nextCursor,
    );
  }
}

class CreateLogResult {
  final int logId;

  const CreateLogResult({required this.logId});
}

class LogsPageResponse {
  final List<Map<String, dynamic>> items;
  final String? nextCursor;

  const LogsPageResponse({required this.items, required this.nextCursor});
}

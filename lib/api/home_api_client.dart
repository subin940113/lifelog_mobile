import 'package:lifelog_mobile/api/auth_api_client.dart';

class HomeApiClient {
  final AuthApiClient _api;

  HomeApiClient(this._api);

  /// GET /api/home
  ///
  /// Returns decoded JSON map:
  /// {
  ///   topInsight: {...},
  ///   insights: [...],
  ///   recentLogs: [...]
  /// }
  Future<Map<String, dynamic>> getHome({
    required String period, // day|week|month
    int limitLogs = 3,
    int limitInsights = 2,
  }) async {
    final safePeriod = (period == 'week' || period == 'month') ? period : 'day';
    final safeLimitLogs = limitLogs.clamp(1, 20);
    final safeLimitInsights = limitInsights.clamp(0, 20);

    final path =
        '/api/home?period=$safePeriod&limitLogs=$safeLimitLogs&limitInsights=$safeLimitInsights';

    return _api.getJson(path);
  }
}
import 'package:lifelog_mobile/api/auth_api_client.dart';

class HomeApiClient {
  final AuthApiClient _api;
  HomeApiClient(this._api);

  /// GET /api/home?limitLogs=3&limitInsights=6
  Future<Map<String, dynamic>> getHome({
    int limitLogs = 3,
    int limitInsights = 6,
  }) async {
    final safeLimitLogs = limitLogs.clamp(1, 20);
    final safeLimitInsights = limitInsights.clamp(0, 20);

    final path =
        '/api/home?limitLogs=$safeLimitLogs&limitInsights=$safeLimitInsights';
    return _api.getJson(path);
  }
}

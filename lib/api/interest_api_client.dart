import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/models/interest_state.dart';

class InterestApiClient {
  final AuthApiClient _api;
  InterestApiClient(this._api);

  /// GET /api/interests
  /// { "keywords": ["발이", "운동", ...] }
  Future<InterestState> getInterests() async {
    final map = await _api.getJson('/api/interests');
    return InterestState.fromJson(map);
  }

  /// POST /api/interests
  /// body: { "keyword": "..." }
  /// res:  { "keywords": [...] }
  Future<InterestState> addKeyword(String keyword) async {
    final map = await _api.postJson('/api/interests', {'keyword': keyword});
    return InterestState.fromJson(map);
  }

  /// POST /api/interests/remove
  /// body: { "keyword": "..." }
  /// res:  { "keywords": [...] }
  Future<InterestState> removeKeyword(String keyword) async {
    final map = await _api.postJson('/api/interests/remove', {
      'keyword': keyword,
    });
    return InterestState.fromJson(map);
  }
}

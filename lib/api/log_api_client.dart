import 'package:lifelog_mobile/api/auth_api_client.dart';

class LogApiClient {
  final AuthApiClient _api;

  LogApiClient(this._api);

  /// POST /api/logs
  Future<CreateLogResult> createLog({
    required String content,
  }) async {
    final res = await _api.postJson(
      '/api/logs',
      {'content': content},
    );

    final logId = res['logId'];
    if (logId is! int) {
      throw Exception('logId가 올바르지 않습니다: $res');
    }

    return CreateLogResult(logId: logId);
  }
}

class CreateLogResult {
  final int logId;

  const CreateLogResult({required this.logId});
}
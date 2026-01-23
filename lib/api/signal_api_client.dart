import 'package:lifelog_mobile/api/auth_api_client.dart';

/// Signal API client
///
/// Pattern matches other clients (e.g. HomeApiClient):
/// - Wraps AuthApiClient
/// - Uses AuthApiClient.getJson() which already handles Authorization + refresh/retry
class SignalApiClient {
  final AuthApiClient _api;

  SignalApiClient(this._api);

  /// GET /api/signal/objects
  Future<SignalObjectsResponse> getObjects() async {
    final map = await _api.getJson('/api/signal/objects');
    return SignalObjectsResponse.fromJson(map);
  }

  /// GET /api/signal/water-drops/{keywordKey}
  Future<WaterDropDetailResponse> getWaterDropDetail(String keywordKey) async {
    final map = await _api.getJson('/api/signal/water-drops/$keywordKey');
    return WaterDropDetailResponse.fromJson(map);
  }
}

// ------------------------------
// Models
// ------------------------------

class SignalObjectsResponse {
  final DateTime serverTime;
  final int totalCandyCount;
  final List<ActiveKeywordDto> activeKeywords;
  final List<WaterDropDto> waterDrops;

  SignalObjectsResponse({
    required this.serverTime,
    required this.totalCandyCount,
    required this.activeKeywords,
    required this.waterDrops,
  });

  factory SignalObjectsResponse.fromJson(Map<String, dynamic> json) {
    return SignalObjectsResponse(
      serverTime: DateTime.parse(json['serverTime'] as String),
      totalCandyCount: (json['totalCandyCount'] as num).toInt(),
      activeKeywords: (json['activeKeywords'] as List<dynamic>)
          .map((e) => ActiveKeywordDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      waterDrops: (json['waterDrops'] as List<dynamic>)
          .map((e) => WaterDropDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ActiveKeywordDto {
  final String keywordKey;
  final String? insightText;
  final int candyCount;
  final DateTime updatedAt;

  ActiveKeywordDto({
    required this.keywordKey,
    required this.insightText,
    required this.candyCount,
    required this.updatedAt,
  });

  factory ActiveKeywordDto.fromJson(Map<String, dynamic> json) {
    return ActiveKeywordDto(
      keywordKey: json['keywordKey'] as String,
      insightText: json['insightText'] as String?,
      candyCount: (json['candyCount'] as num).toInt(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class WaterDropDto {
  final String keywordKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? snapshotText;

  WaterDropDto({
    required this.keywordKey,
    required this.createdAt,
    required this.updatedAt,
    required this.snapshotText,
  });

  factory WaterDropDto.fromJson(Map<String, dynamic> json) {
    return WaterDropDto(
      keywordKey: json['keywordKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      snapshotText: json['snapshotText'] as String?,
    );
  }
}

class WaterDropDetailResponse {
  final String keywordKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? snapshotText;

  WaterDropDetailResponse({
    required this.keywordKey,
    required this.createdAt,
    required this.updatedAt,
    required this.snapshotText,
  });

  factory WaterDropDetailResponse.fromJson(Map<String, dynamic> json) {
    return WaterDropDetailResponse(
      keywordKey: json['keywordKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      snapshotText: json['snapshotText'] as String?,
    );
  }
}

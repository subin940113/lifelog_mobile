// lib/api/insight_feedback_api_client.dart
import 'package:lifelog_mobile/api/auth_api_client.dart';

/// Mirrors the style of InsightApiClient:
/// - wraps AuthApiClient
/// - uses getJson/postJson
/// - minimal DTOs + enum wire mapping
///
/// Assumed endpoints (adjust if your server differs):
/// GET /api/insights/{insightId}/feedback
/// POST /api/insights/{insightId}/feedback
/// body:
/// {
///   "vote": "LIKE" | "DISLIKE",
///   "reason": "TOO_OBVIOUS" | "DUPLICATE" | "TOO_SHARP" | "NOT_RELEVANT" | "BAD_TIMING" | "OTHER" (optional),
///   "comment": "..." (optional)
/// }
///
/// response (optional): can be empty or JSON; we parse a simple ack if present.
class InsightFeedbackApiClient {
  final AuthApiClient _api;
  InsightFeedbackApiClient(this._api);

  /// GET /api/insights/{insightId}/feedback
  /// expected:
  /// { "feedback": { ... } }  OR  { ... }  OR  { "feedback": null }
  Future<InsightFeedbackView?> getOne({required int insightId}) async {
    final map = await _api.getJson('/api/insights/$insightId/feedback');

    // Tolerate either wrapped or direct payload
    final dynamic raw = map.containsKey('feedback') ? map['feedback'] : map;

    if (raw == null) return null;
    if (raw is! Map) return null;

    return InsightFeedbackView.fromJson(raw.cast<String, dynamic>());
  }

  /// POST /api/insights/{insightId}/feedback
  Future<InsightFeedbackAck> submit({
    required int insightId,
    required InsightFeedbackVote vote,
    InsightFeedbackReason? reason,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'vote': vote.toWire(),
      if (reason != null) 'reason': reason.toWire(),
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    };

    // Some backends return {} or an ack payload.
    // AuthApiClient.postJson expects JSON; keep it consistent.
    final map = await _api.postJson('/api/insights/$insightId/feedback', body);

    return InsightFeedbackAck.fromJson(map);
  }
}

/// Feedback vote (UI -> API)
enum InsightFeedbackVote {
  like,
  dislike;

  String toWire() {
    switch (this) {
      case InsightFeedbackVote.like:
        return 'LIKE';
      case InsightFeedbackVote.dislike:
        return 'DISLIKE';
    }
  }

  static InsightFeedbackVote? fromWire(String? v) {
    switch ((v ?? '').trim().toUpperCase()) {
      case 'LIKE':
        return InsightFeedbackVote.like;
      case 'DISLIKE':
        return InsightFeedbackVote.dislike;
      default:
        return null;
    }
  }
}

/// Dislike reasons (UI -> API)
enum InsightFeedbackReason {
  tooObvious,
  duplicate,
  tooSharp,
  notRelevant,
  badTiming,
  other;

  String toWire() {
    switch (this) {
      case InsightFeedbackReason.tooObvious:
        return 'TOO_OBVIOUS';
      case InsightFeedbackReason.duplicate:
        return 'DUPLICATE';
      case InsightFeedbackReason.tooSharp:
        return 'TOO_SHARP';
      case InsightFeedbackReason.notRelevant:
        return 'NOT_RELEVANT';
      case InsightFeedbackReason.badTiming:
        return 'BAD_TIMING';
      case InsightFeedbackReason.other:
        return 'OTHER';
    }
  }

  static InsightFeedbackReason? fromWire(String? v) {
    switch ((v ?? '').trim().toUpperCase()) {
      case 'TOO_OBVIOUS':
        return InsightFeedbackReason.tooObvious;
      case 'DUPLICATE':
        return InsightFeedbackReason.duplicate;
      case 'TOO_SHARP':
        return InsightFeedbackReason.tooSharp;
      case 'NOT_RELEVANT':
        return InsightFeedbackReason.notRelevant;
      case 'BAD_TIMING':
        return InsightFeedbackReason.badTiming;
      case 'OTHER':
        return InsightFeedbackReason.other;
      default:
        return null;
    }
  }
}

class InsightFeedbackView {
  final int insightId;
  final InsightFeedbackVote vote;
  final InsightFeedbackReason? reason;
  final String? comment;
  final String? updatedAt; // keep as string to avoid bringing in date parsing deps

  const InsightFeedbackView({
    required this.insightId,
    required this.vote,
    required this.reason,
    required this.comment,
    required this.updatedAt,
  });

  factory InsightFeedbackView.fromJson(Map<String, dynamic> m) {
    final idRaw = m['insightId'];
    final insightId = (idRaw is num) ? idRaw.toInt() : int.tryParse('$idRaw') ?? 0;

    final vote = InsightFeedbackVote.fromWire(m['vote'] as String?) ?? InsightFeedbackVote.like;

    final reason = InsightFeedbackReason.fromWire(m['reason'] as String?);

    final commentRaw = m['comment'];
    final comment = (commentRaw is String && commentRaw.trim().isNotEmpty) ? commentRaw.trim() : null;

    final updatedRaw = m['updatedAt'];
    final updatedAt = (updatedRaw is String && updatedRaw.trim().isNotEmpty) ? updatedRaw.trim() : null;

    return InsightFeedbackView(
      insightId: insightId,
      vote: vote,
      reason: reason,
      comment: comment,
      updatedAt: updatedAt,
    );
  }
}

/// Optional ack payload.
/// If your server returns something else, adapt here only.
///
/// Suggested response examples:
/// { "ok": true }
/// { "saved": true }
/// { }  (empty object)
class InsightFeedbackAck {
  final bool ok;

  const InsightFeedbackAck({required this.ok});

  factory InsightFeedbackAck.fromJson(Map<String, dynamic> m) {
    final v = m['ok'];
    final saved = m['saved'];
    // If server returns empty {}, treat as success because HTTP 2xx already means ok.
    final resolved =
        (v is bool) ? v : (saved is bool) ? saved : true;
    return InsightFeedbackAck(ok: resolved);
  }
}
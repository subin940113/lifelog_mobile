class InterestState {
  final bool enabled;
  final List<String> keywords;

  const InterestState({
    required this.enabled,
    required this.keywords,
  });

  factory InterestState.fromJson(Map<String, dynamic> m) {
    final enabled = m['enabled'] == true;

    final rawKeywords = m['keywords'];
    final List<String> keywords = (rawKeywords is List)
        ? rawKeywords
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    return InterestState(enabled: enabled, keywords: keywords);
  }
}
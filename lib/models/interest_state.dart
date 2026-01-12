class InterestState {
  final List<String> keywords;

  const InterestState({required this.keywords});

  factory InterestState.fromJson(Map<String, dynamic> m) {
    final list = (m['keywords'] as List?) ?? const [];
    return InterestState(
      keywords: list
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}

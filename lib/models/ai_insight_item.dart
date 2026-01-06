class AiInsightItem {
  final String kind; // TENDENCY/PATTERN/HIGHLIGHT/WARNING/REFLECTION etc
  final String title;
  final String body;
  final String? evidence;
  final String? keyword; // optional grouping key

  const AiInsightItem({
    required this.kind,
    required this.title,
    required this.body,
    this.evidence,
    this.keyword,
  });

  factory AiInsightItem.fromJson(Map<String, dynamic> m) {
    return AiInsightItem(
      kind: (m['kind'] as String?) ?? 'TENDENCY',
      title: (m['title'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      evidence: (m['evidence'] as String?),
      keyword: (m['keyword'] as String?)?.trim().isEmpty == true ? null : (m['keyword'] as String?),
    );
  }
}
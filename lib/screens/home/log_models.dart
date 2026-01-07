class LogPreview {
  final int logId;
  final String dateLabel; // e.g. "2026.01.05"
  final String timeLabel; // e.g. "19:55"
  final String preview;

  const LogPreview({
    required this.logId,
    required this.dateLabel,
    required this.timeLabel,
    required this.preview,
  });

  factory LogPreview.fromJson(Map<String, dynamic> m) {
    final logIdRaw = m['logId'];
    final logId = (logIdRaw is int) ? logIdRaw : int.tryParse('$logIdRaw') ?? 0;

    return LogPreview(
      logId: logId,
      dateLabel: (m['dateLabel'] as String?)?.trim().isNotEmpty == true
          ? (m['dateLabel'] as String).trim()
          : '—',
      timeLabel: (m['timeLabel'] as String?)?.trim().isNotEmpty == true
          ? (m['timeLabel'] as String).trim()
          : '—',
      preview: (m['preview'] as String?) ?? '',
    );
  }
}

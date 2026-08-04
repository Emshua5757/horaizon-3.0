/// History item DTO for shua.resume.history.list HBP v2 RPC response.
///
/// Each item in the `items` list maps directly to a `resume_history` SQLite
/// row via the Go `HistoryItem` struct (string-keyed msgpack).
class ResumeHistoryItemDto {
  final String exhibitId;
  final String vaultUrl;
  final String templateId;
  final String jobDesc;
  final double? tailorScore;
  final bool aiEnhanced;
  final int durationMs;
  final DateTime compiledAt;

  const ResumeHistoryItemDto({
    required this.exhibitId,
    required this.vaultUrl,
    required this.templateId,
    required this.jobDesc,
    this.tailorScore,
    required this.aiEnhanced,
    required this.durationMs,
    required this.compiledAt,
  });

  factory ResumeHistoryItemDto.fromMap(Map<dynamic, dynamic> m) {
    DateTime parsedAt;
    try {
      parsedAt = DateTime.parse((m['compiled_at'] ?? '') as String);
    } catch (_) {
      parsedAt = DateTime.now();
    }

    double? score;
    final rawScore = m['tailor_score'];
    if (rawScore is double) {
      score = rawScore;
    } else if (rawScore is num) {
      score = rawScore.toDouble();
    }

    return ResumeHistoryItemDto(
      exhibitId: (m['exhibit_id'] ?? '') as String,
      vaultUrl: (m['vault_url'] ?? '') as String,
      templateId: (m['template_id'] ?? '') as String,
      jobDesc: (m['job_desc'] ?? '') as String,
      tailorScore: score,
      aiEnhanced: (m['ai_enhanced'] ?? false) as bool,
      durationMs: ((m['duration_ms'] ?? 0) as num).toInt(),
      compiledAt: parsedAt,
    );
  }

  /// Formatted date string for display: "Aug 4, 2026"
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[compiledAt.month - 1]} ${compiledAt.day}, ${compiledAt.year}';
  }

  /// Duration in seconds, formatted: "1.2s"
  String get formattedDuration =>
      '${(durationMs / 1000).toStringAsFixed(1)}s';

  /// File name for download/share: "resume_default_20260804.pdf"
  String get fileName =>
      'resume_${templateId}_'
      '${compiledAt.year}'
      '${compiledAt.month.toString().padLeft(2, '0')}'
      '${compiledAt.day.toString().padLeft(2, '0')}.pdf';
}

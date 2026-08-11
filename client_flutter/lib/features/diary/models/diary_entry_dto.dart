/// DiaryEntryDto — wire DTO for shua.diary.entry.* HBP v2 operations.
/// Maps to diary_entries table in shua_diary.db.
///
/// All fields match diary_types.ts DiaryEntry interface (camelCase → snake_case on wire).
class DiaryEntryDto {
  final String id;
  final String userId;
  final String title;
  final bool isPrivate;
  final String aiProvider;
  final String lexoRank;
  final String preview;
  final double? moodScore;
  final double? energyScore;
  final bool isGloballyElevated;
  final DateTime loggedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryEntryDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.isPrivate,
    required this.aiProvider,
    required this.lexoRank,
    required this.preview,
    this.moodScore,
    this.energyScore,
    required this.isGloballyElevated,
    required this.loggedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryEntryDto.fromMap(Map<dynamic, dynamic> m) {
    return DiaryEntryDto(
      id:                 m['id'] as String,
      userId:             m['userId'] as String? ?? 'shua',
      title:              m['title'] as String? ?? 'Untitled',
      isPrivate:          m['isPrivate'] as bool? ?? false,
      aiProvider:         m['aiProvider'] as String? ?? 'ollama',
      lexoRank:           m['lexoRank'] as String? ?? '',
      preview:            m['preview'] as String? ?? '',
      moodScore:          (m['moodScore'] as num?)?.toDouble(),
      energyScore:        (m['energyScore'] as num?)?.toDouble(),
      isGloballyElevated: m['isGloballyElevated'] as bool? ?? false,
      loggedAt:           DateTime.parse(m['loggedAt'] as String),
      createdAt:          DateTime.parse(m['createdAt'] as String),
      updatedAt:          DateTime.parse(m['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id':                 id,
    'userId':             userId,
    'title':              title,
    'isPrivate':          isPrivate,
    'aiProvider':         aiProvider,
    'lexoRank':           lexoRank,
    'preview':            preview,
    'moodScore':          moodScore,
    'energyScore':        energyScore,
    'isGloballyElevated': isGloballyElevated,
    'loggedAt':           loggedAt.toIso8601String(),
    'createdAt':          createdAt.toIso8601String(),
    'updatedAt':          updatedAt.toIso8601String(),
  };

  DiaryEntryDto copyWith({
    String? title,
    bool? isPrivate,
    bool? isGloballyElevated,
    double? moodScore,
    double? energyScore,
    String? preview,
    DateTime? loggedAt,
  }) {
    return DiaryEntryDto(
      id:                 id,
      userId:             userId,
      title:              title ?? this.title,
      isPrivate:          isPrivate ?? this.isPrivate,
      aiProvider:         aiProvider,
      lexoRank:           lexoRank,
      preview:            preview ?? this.preview,
      moodScore:          moodScore ?? this.moodScore,
      energyScore:        energyScore ?? this.energyScore,
      isGloballyElevated: isGloballyElevated ?? this.isGloballyElevated,
      loggedAt:           loggedAt ?? this.loggedAt,
      createdAt:          createdAt,
      updatedAt:          DateTime.now(),
    );
  }
}

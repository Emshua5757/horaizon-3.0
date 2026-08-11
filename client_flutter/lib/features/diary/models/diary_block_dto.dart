import 'dart:convert';

/// DiaryBlockDto — wire DTO for shua.diary.block.* HBP v2 operations.
/// Maps to diary_blocks table in shua_diary.db.
///
/// [content] is a raw JSON string — each block type interprets it differently.
/// [version] is the optimistic lock counter — must be echoed back on save.
class DiaryBlockDto {
  final String id;
  final String entryId;
  final String blockType;
  final String content; // Raw JSON string — block widget parses this
  final String lexoRank;
  final int version;    // Optimistic lock — increment on server each update
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryBlockDto({
    required this.id,
    required this.entryId,
    required this.blockType,
    required this.content,
    required this.lexoRank,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryBlockDto.fromMap(Map<dynamic, dynamic> m) {
    return DiaryBlockDto(
      id:        m['id'] as String,
      entryId:   m['entryId'] as String,
      blockType: m['blockType'] as String,
      content:   m['content'] as String? ?? '{}',
      lexoRank:  m['lexoRank'] as String? ?? '',
      version:   (m['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(m['createdAt'] as String),
      updatedAt: DateTime.parse(m['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id':        id,
    'entryId':   entryId,
    'blockType': blockType,
    'content':   content,
    'lexoRank':  lexoRank,
    'version':   version,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  DiaryBlockDto copyWith({String? content, int? version, String? lexoRank}) {
    return DiaryBlockDto(
      id:        id,
      entryId:   entryId,
      blockType: blockType,
      content:   content ?? this.content,
      lexoRank:  lexoRank ?? this.lexoRank,
      version:   version ?? this.version,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Convenience: parse content as a JSON map.
  /// Returns empty map on parse failure — block widget handles gracefully.
  Map<String, dynamic> get contentAsMap {
    try {
      // ignore: avoid_dynamic_calls
      return Map<String, dynamic>.from(
        (content.isEmpty ? {} : _jsonDecode(content)) as Map,
      );
    } catch (_) {
      return {};
    }
  }

  /// Plain text preview for search result display.
  String get textPreview {
    final m = contentAsMap;
    final raw = (m['text'] ?? m['value'] ?? m['title'] ?? '').toString();
    return raw.isEmpty ? content.substring(0, content.length.clamp(0, 80)) : raw.substring(0, raw.length.clamp(0, 80));
  }
}

Map<String, dynamic> _jsonDecode(String s) {
  try {
    return jsonDecode(s) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../models/diary_entry_dto.dart';

class DiarySearchResultDto extends DiaryEntryDto {
  final String? snippet;

  const DiarySearchResultDto({
    required super.id,
    required super.userId,
    required super.title,
    required super.isPrivate,
    required super.aiProvider,
    required super.lexoRank,
    required super.preview,
    super.moodScore,
    super.energyScore,
    required super.isGloballyElevated,
    required super.loggedAt,
    required super.createdAt,
    required super.updatedAt,
    this.snippet,
  });

  factory DiarySearchResultDto.fromMap(Map<dynamic, dynamic> m) {
    return DiarySearchResultDto(
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
      snippet:            m['snippet'] as String?,
    );
  }
}

final diarySearchQueryProvider = StateProvider<String>((ref) => '');

final diarySearchResultsProvider = FutureProvider<List<DiarySearchResultDto>>((ref) async {
  final query = ref.watch(diarySearchQueryProvider).trim();
  if (query.isEmpty) return [];

  final hbp = await ref.watch(hbpClientProvider.future);
  final p = Packer()
    ..packMapLength(1)
    ..packString('query')
    ..packString(query);

  final resp = await hbp.send(HbpFrame.request('shua.diary', 'search', p.takeBytes()));
  if (resp.payload.isEmpty) return [];

  try {
    final u = Unpacker(Uint8List.fromList(resp.payload));
    final len = u.unpackListLength();
    final list = <DiarySearchResultDto>[];
    for (var i = 0; i < len; i++) {
      final map = _unpackMap(u);
      if (map.isNotEmpty) {
        list.add(DiarySearchResultDto.fromMap(map));
      }
    }
    return list;
  } catch (_) {
    return [];
  }
});

Map<String, dynamic> _unpackMap(Unpacker u) {
  try {
    final len = u.unpackMapLength();
    final map = <String, dynamic>{};
    for (var i = 0; i < len; i++) {
      final k = u.unpackString();
      if (k == null) continue;
      map[k] = _unpackValue(u);
    }
    return map;
  } catch (_) {
    return {};
  }
}

dynamic _unpackValue(Unpacker u) {
  try { return u.unpackString(); } catch (_) {
    try { return u.unpackInt(); } catch (_) {
      try { return u.unpackBool(); } catch (_) {
        try { return u.unpackDouble(); } catch (_) {
          return null;
        }
      }
    }
  }
}

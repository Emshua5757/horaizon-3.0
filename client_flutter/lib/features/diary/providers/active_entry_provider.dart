import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../models/diary_entry_dto.dart';
import '../models/diary_block_dto.dart';

class ActiveEntryState {
  final DiaryEntryDto entry;
  final List<DiaryBlockDto> blocks;
  final bool isSaving;

  const ActiveEntryState({
    required this.entry,
    required this.blocks,
    this.isSaving = false,
  });

  ActiveEntryState copyWith({
    DiaryEntryDto? entry,
    List<DiaryBlockDto>? blocks,
    bool? isSaving,
  }) {
    return ActiveEntryState(
      entry:    entry    ?? this.entry,
      blocks:   blocks   ?? this.blocks,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

final activeEntryNotifierProvider = AsyncNotifierProvider.family<
    ActiveEntryNotifier, ActiveEntryState, String>(
  ActiveEntryNotifier.new,
);

class ActiveEntryNotifier
    extends FamilyAsyncNotifier<ActiveEntryState, String> {
  StreamSubscription<HbpFrame>? _eventSub;

  @override
  Future<ActiveEntryState> build(String arg) async {
    final hbp = await ref.watch(hbpClientProvider.future);

    _eventSub?.cancel();
    _eventSub = hbp.events.listen((frame) {
      if (frame.op == 'shua.diary.entry.updated') {
        ref.invalidateSelf();
      }
    });

    ref.onDispose(() => _eventSub?.cancel());

    return _fetchEntry(hbp, arg);
  }

  Future<ActiveEntryState> _fetchEntry(dynamic hbp, String id) async {
    final p = Packer()
      ..packMapLength(2)
      ..packString('entry_id')
      ..packString(id)
      ..packString('subscribe_entry_id')
      ..packString(id);

    final resp = await hbp.send(HbpFrame.request('shua.diary', 'entry.get', p.takeBytes()));
    return _decodeEntryState(resp, id);
  }

  ActiveEntryState _decodeEntryState(HbpFrame frame, String fallbackId) {
    if (frame.payload.isEmpty) {
      throw StateError('Entry not found: $fallbackId');
    }
    final u = Unpacker(Uint8List.fromList(frame.payload));
    final topMap = _unpackMap(u);

    final entryMap = topMap['entry'] as Map? ?? {};
    final blocksList = topMap['blocks'] as List? ?? [];

    final entry = DiaryEntryDto.fromMap(entryMap);
    final blocks = blocksList.map((b) => DiaryBlockDto.fromMap(b as Map)).toList();

    return ActiveEntryState(entry: entry, blocks: blocks);
  }

  Map<String, dynamic> _unpackMap(Unpacker u) {
    try {
      final len = u.unpackMapLength();
      final map = <String, dynamic>{};
      for (var i = 0; i < len; i++) {
        final k = u.unpackString();
        if (k == null) continue;
        if (k == 'entry') {
          map[k] = _unpackMap(u);
        } else if (k == 'blocks') {
          final bLen = u.unpackListLength();
          final bList = <Map<String, dynamic>>[];
          for (var j = 0; j < bLen; j++) {
            bList.add(_unpackMap(u));
          }
          map[k] = bList;
        } else {
          map[k] = _unpackValue(u);
        }
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

  Future<void> updateTitle(String title) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(entry: current.entry.copyWith(title: title)));

    final hbp = await ref.read(hbpClientProvider.future);
    final p = Packer()
      ..packMapLength(2)
      ..packString('entry_id')
      ..packString(current.entry.id)
      ..packString('title')
      ..packString(title);
    await hbp.send(HbpFrame.request('shua.diary', 'entry.save', p.takeBytes()));
  }

  Future<void> togglePrivate() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final newVal = !current.entry.isPrivate;
    state = AsyncData(current.copyWith(entry: current.entry.copyWith(isPrivate: newVal)));

    final hbp = await ref.read(hbpClientProvider.future);
    final p = Packer()
      ..packMapLength(2)
      ..packString('entry_id')
      ..packString(current.entry.id)
      ..packString('is_private')
      ..packBool(newVal);
    await hbp.send(HbpFrame.request('shua.diary', 'entry.save', p.takeBytes()));
  }

  Future<DiaryBlockDto?> createBlock(String blockType, {String? afterLexoRank}) async {
    final current = state.valueOrNull;
    if (current == null) return null;

    final hbp = await ref.read(hbpClientProvider.future);
    final p = Packer()
      ..packMapLength(afterLexoRank != null ? 3 : 2)
      ..packString('entry_id')
      ..packString(current.entry.id)
      ..packString('block_type')
      ..packString(blockType);

    if (afterLexoRank != null) {
      p.packString('after_lexo_rank');
      p.packString(afterLexoRank);
    }

    final resp = await hbp.send(HbpFrame.request('shua.diary', 'block.save', p.takeBytes()));
    if (resp.payload.isEmpty) return null;

    final u = Unpacker(Uint8List.fromList(resp.payload));
    final itemMap = _unpackMap(u);
    if (itemMap.isEmpty) return null;

    final newBlock = DiaryBlockDto.fromMap(itemMap);
    state = AsyncData(current.copyWith(blocks: [...current.blocks, newBlock]));
    return newBlock;
  }

  Future<void> updateBlock(String blockId, Map<String, dynamic> contentMap) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final idx = current.blocks.indexWhere((b) => b.id == blockId);
    if (idx == -1) return;

    final block   = current.blocks[idx];
    final content = jsonEncode(contentMap);

    final optimistic = block.copyWith(content: content, version: block.version + 1);
    final newBlocks = [...current.blocks];
    newBlocks[idx] = optimistic;
    state = AsyncData(current.copyWith(blocks: newBlocks));

    final hbp = await ref.read(hbpClientProvider.future);
    final p = Packer()
      ..packMapLength(4)
      ..packString('block_id')
      ..packString(blockId)
      ..packString('entry_id')
      ..packString(current.entry.id)
      ..packString('content')
      ..packString(content)
      ..packString('version')
      ..packInt(block.version);

    await hbp.send(HbpFrame.request('shua.diary', 'block.save', p.takeBytes()));
  }

  Future<void> deleteBlock(String blockId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(
      blocks: current.blocks.where((b) => b.id != blockId).toList(),
    ));

    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final p = Packer()
        ..packMapLength(1)
        ..packString('block_id')
        ..packString(blockId);
      await hbp.send(HbpFrame.request('shua.diary', 'block.delete', p.takeBytes()));
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> reorderBlock(
    String blockId, {
    String? beforeBlockId,
    String? afterBlockId,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final hbp = await ref.read(hbpClientProvider.future);
    final p = Packer()
      ..packMapLength(4)
      ..packString('entry_id')
      ..packString(current.entry.id)
      ..packString('block_id')
      ..packString(blockId)
      ..packString('before_block_id')
      ..packString(beforeBlockId ?? '')
      ..packString('after_block_id')
      ..packString(afterBlockId ?? '');

    await hbp.send(HbpFrame.request('shua.diary', 'block.reorder', p.takeBytes()));
  }

  /// Instantly reorder blocks in local State for O(1) drag-and-drop feedback
  void reorderBlocksLocally(int oldIndex, int newIndex) {
    final current = state.valueOrNull;
    if (current == null) return;

    final blocks = [...current.blocks];
    final moved = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, moved);
    state = AsyncData(current.copyWith(blocks: blocks));
  }

  /// Bulk import blocks from a JSON string payload.
  /// Supports raw List of block maps or an Object with a "blocks" array.
  Future<int> importBlocksFromJson(String jsonStr) async {
    final current = state.valueOrNull;
    if (current == null) return 0;

    dynamic parsed;
    try {
      parsed = jsonDecode(jsonStr);
    } catch (_) {
      throw const FormatException('Invalid JSON format');
    }

    List<dynamic> blockList = [];
    if (parsed is List) {
      blockList = parsed;
    } else if (parsed is Map && parsed['blocks'] is List) {
      blockList = parsed['blocks'] as List;
      if (parsed['title'] != null && parsed['title'].toString().isNotEmpty) {
        await updateTitle(parsed['title'].toString());
      }
    } else {
      throw const FormatException('JSON must be a list of blocks or an object containing a "blocks" array');
    }

    int count = 0;
    for (final item in blockList) {
      if (item is! Map) continue;
      final type = (item['type'] ?? item['block_type'] ?? 'markdown').toString();
      final rawContent = item['content'];

      final Map<String, dynamic> contentMap = rawContent is Map
          ? Map<String, dynamic>.from(rawContent)
          : rawContent is String
              ? {'text': rawContent}
              : {};

      final created = await createBlock(type);
      if (created != null && contentMap.isNotEmpty) {
        await updateBlock(created.id, contentMap);
        count++;
      }
    }

    return count;
  }
}

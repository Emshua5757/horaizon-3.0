import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../core/hbp/hbp_client_provider.dart';
import '../../core/hbp/hbp_frame.dart';
import 'models/diary_entry_dto.dart';
import 'models/diary_block_dto.dart';

/// Combined state for an open diary entry.
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

/// ActiveEntryNotifier — manages the editor state for a single open diary entry.
///
/// Key behaviours:
///   - Fetches entry + blocks on first build via shua.diary.entry.get.
///   - Listens to shua.diary.entry.updated events for multi-device sync.
///   - Block saves use optimistic locking (version field).
///   - On version conflict: refreshes block from server automatically.
///
/// Time Complexity: O(B) block list render. O(1) per block save.
/// Space Complexity: O(B) for B blocks in the open entry.
@riverpod
class ActiveEntryNotifier extends _$ActiveEntryNotifier {
  StreamSubscription<HbpFrame>? _eventSub;

  @override
  Future<ActiveEntryState> build(String entryId) async {
    final hbp = await ref.watch(hbpClientProvider.future);

    // Subscribe to live entry.updated pushes for this entry
    _eventSub?.cancel();
    _eventSub = hbp.events.listen((frame) {
      if (frame.op == 'entry.updated') {
        final raw = frame.payloadDecoded as Map?;
        if (raw?['entry_id'] == entryId) {
          _syncBlock(hbp, raw!['block_id'] as String, raw['version'] as int);
        }
      }
    });

    ref.onDispose(() => _eventSub?.cancel());

    return _fetchEntry(hbp, entryId);
  }

  Future<ActiveEntryState> _fetchEntry(dynamic hbp, String id) async {
    final p = Packer()
      ..packMapLength(2)
      ..packString('entry_id')
      ..packString(id)
      ..packString('subscribe_entry_id')
      ..packString(id); // Ask server to push entry.updated events to this client

    final resp = await hbp.send(HbpFrame.request('shua.diary', 'entry.get', p.takeBytes()));
    final raw = resp.payloadDecoded as Map;

    final entry  = DiaryEntryDto.fromMap(raw['entry'] as Map);
    final blocks = (raw['blocks'] as List)
        .map((b) => DiaryBlockDto.fromMap(b as Map))
        .toList();

    return ActiveEntryState(entry: entry, blocks: blocks);
  }

  /// Sync a single block from server after an entry.updated push.
  void _syncBlock(dynamic hbp, String blockId, int serverVersion) {
    final current = state.valueOrNull;
    if (current == null) return;

    // If server version is newer, refresh that block
    final idx = current.blocks.indexWhere((b) => b.id == blockId);
    if (idx == -1) {
      // New block added by another device — full refresh
      ref.invalidateSelf();
      return;
    }

    final localBlock = current.blocks[idx];
    if (localBlock.version < serverVersion) {
      // Fetch updated block content
      _fetchSingleBlock(hbp, blockId).then((updated) {
        if (updated == null) return;
        final newBlocks = [...current.blocks];
        newBlocks[idx] = updated;
        state = AsyncData(current.copyWith(blocks: newBlocks));
      });
    }
  }

  Future<DiaryBlockDto?> _fetchSingleBlock(dynamic hbp, String blockId) async {
    // Use entry.get to refresh all blocks — simpler than a per-block get op
    final current = state.valueOrNull;
    if (current == null) return null;
    try {
      final refreshed = await _fetchEntry(hbp, current.entry.id);
      return refreshed.blocks.firstWhere((b) => b.id == blockId);
    } catch (_) {
      return null;
    }
  }

  // ── Entry mutations ────────────────────────────────────────────────────────

  /// Update entry title — debounced by the UI, called on editing complete.
  Future<void> updateTitle(String title) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic
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

  /// Toggle private flag on the entry.
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

  // ── Block mutations ───────────────────────────────────────────────────────

  /// Create a new block at the end or after a given lexoRank.
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
    final raw = resp.payloadDecoded;
    if (raw is! Map) return null;

    final newBlock = DiaryBlockDto.fromMap(raw);
    state = AsyncData(current.copyWith(blocks: [...current.blocks, newBlock]));
    return newBlock;
  }

  /// Update block content with optimistic locking.
  /// If a version conflict is returned, the block is refreshed from server.
  Future<void> updateBlock(String blockId, Map<String, dynamic> contentMap) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final idx = current.blocks.indexWhere((b) => b.id == blockId);
    if (idx == -1) return;

    final block   = current.blocks[idx];
    final content = jsonEncode(contentMap);

    // Optimistic update
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
      ..packInt(block.version); // Send the ORIGINAL version for conflict check

    final resp = await hbp.send(HbpFrame.request('shua.diary', 'block.save', p.takeBytes()));
    final raw = resp.payloadDecoded;

    if (raw is Map && raw['error'] == 'conflict') {
      // Conflict: server has a newer version — use server's latest
      final serverBlock = DiaryBlockDto.fromMap(raw['latest'] as Map);
      final resolved = [...current.blocks];
      resolved[idx] = serverBlock;
      state = AsyncData(current.copyWith(blocks: resolved));
    }
    // On success: state is already optimistic-updated above
  }

  /// Delete a block by ID.
  Future<void> deleteBlock(String blockId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic remove
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
      // On failure: re-fetch the entry
      ref.invalidateSelf();
    }
  }

  /// Reorder a block using neighbor IDs (server computes new LexoRank).
  Future<void> reorderBlock(
    String blockId, {
    String? beforeBlockId,
    String? afterBlockId,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic reorder: reorder blocks list locally
    // (Server will confirm with entry.updated push)

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
}

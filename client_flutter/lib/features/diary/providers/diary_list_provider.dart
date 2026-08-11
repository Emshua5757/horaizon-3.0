import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../core/hbp/hbp_client_provider.dart';
import '../../core/hbp/hbp_frame.dart';
import 'models/diary_entry_dto.dart';
import 'models/diary_ops.dart';

/// DiaryListNotifier — loads and manages the full diary entry list.
///
/// Lifecycle:
///   1. Fetches all entries via shua.diary.entry.list on first build.
///   2. Listens for shua.diary.entry.updated events to trigger refresh.
///   3. Exposes createEntry / deleteEntry mutators with optimistic UI.
///
/// Time Complexity: O(N) for list render. O(1) for optimistic local mutations.
@riverpod
class DiaryListNotifier extends _$DiaryListNotifier {
  StreamSubscription<HbpFrame>? _eventSub;

  @override
  Future<List<DiaryEntryDto>> build() async {
    final hbp = await ref.watch(hbpClientProvider.future);

    // Subscribe to server-pushed entry.updated events to refresh the list
    _eventSub?.cancel();
    _eventSub = hbp.events.listen((frame) {
      if (frame.op == 'entry.updated') {
        // Refresh the full list on any entry change (entry list changes on title update)
        ref.invalidateSelf();
      }
    });

    ref.onDispose(() => _eventSub?.cancel());

    return _fetchList(hbp);
  }

  Future<List<DiaryEntryDto>> _fetchList(dynamic hbp) async {
    final p = Packer()..packMapLength(0);
    final resp = await hbp.send(HbpFrame.request('shua.diary', 'entry.list', p.takeBytes()));
    final raw = resp.payloadDecoded;
    if (raw is! List) return [];
    return raw.map((m) => DiaryEntryDto.fromMap(m as Map)).toList();
  }

  /// Create a new entry and optimistically prepend it to the list.
  Future<DiaryEntryDto?> createEntry({
    String title = 'Untitled',
    DateTime? loggedAt,
  }) async {
    final hbp = await ref.read(hbpClientProvider.future);
    final p = Packer()
      ..packMapLength(2)
      ..packString('title')
      ..packString(title)
      ..packString('logged_at')
      ..packString((loggedAt ?? DateTime.now()).toIso8601String());

    final resp = await hbp.send(HbpFrame.request('shua.diary', 'entry.create', p.takeBytes()));
    final raw = resp.payloadDecoded;
    if (raw is! Map) return null;

    final entry = DiaryEntryDto.fromMap(raw);

    // Optimistic: prepend to list immediately
    final current = state.valueOrNull ?? [];
    state = AsyncData([entry, ...current]);

    return entry;
  }

  /// Delete an entry and remove it from the list optimistically.
  Future<void> deleteEntry(String entryId) async {
    final current = state.valueOrNull ?? [];

    // Optimistic: remove immediately
    state = AsyncData(current.where((e) => e.id != entryId).toList());

    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final p = Packer()
        ..packMapLength(1)
        ..packString('entry_id')
        ..packString(entryId);
      await hbp.send(HbpFrame.request('shua.diary', 'entry.delete', p.takeBytes()));
    } catch (_) {
      // Rollback on failure
      state = AsyncData(current);
    }
  }
}

/// Provider for the diary list state
final diaryListProvider = diaryListNotifierProvider;

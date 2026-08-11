import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../models/diary_entry_dto.dart';

final diaryListProvider =
    AsyncNotifierProvider<DiaryListNotifier, List<DiaryEntryDto>>(
  DiaryListNotifier.new,
);

class DiaryListNotifier extends AsyncNotifier<List<DiaryEntryDto>> {
  StreamSubscription<HbpFrame>? _eventSub;

  @override
  Future<List<DiaryEntryDto>> build() async {
    final hbp = await ref.watch(hbpClientProvider.future);

    _eventSub?.cancel();
    _eventSub = hbp.events.listen((frame) {
      if (frame.op == 'shua.diary.entry.updated') {
        ref.invalidateSelf();
      }
    });

    ref.onDispose(() => _eventSub?.cancel());

    return _fetchList(hbp);
  }

  Future<List<DiaryEntryDto>> _fetchList(dynamic hbp) async {
    final reqFrame = HbpFrame.request('shua.diary', 'entry.list', []);
    final resp = await hbp.send(reqFrame);
    return _decodeList(resp);
  }

  List<DiaryEntryDto> _decodeList(HbpFrame frame) {
    if (frame.payload.isEmpty) return [];
    try {
      final u = Unpacker(Uint8List.fromList(frame.payload));
      final len = u.unpackListLength();
      final list = <DiaryEntryDto>[];
      for (var i = 0; i < len; i++) {
        final itemMap = _unpackMap(u);
        if (itemMap.isNotEmpty) {
          list.add(DiaryEntryDto.fromMap(itemMap));
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _unpackMap(Unpacker u) {
    try {
      final len = u.unpackMapLength();
      final map = <String, dynamic>{};
      for (var i = 0; i < len; i++) {
        final k = u.unpackString();
        if (k == null) continue;
        final v = _unpackValue(u);
        map[k] = v;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  dynamic _unpackValue(Unpacker u) {
    try {
      return u.unpackString();
    } catch (_) {
      try { return u.unpackInt(); } catch (_) {
        try { return u.unpackBool(); } catch (_) {
          try { return u.unpackDouble(); } catch (_) {
            return null;
          }
        }
      }
    }
  }

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
    if (resp.payload.isEmpty) return null;

    final u = Unpacker(Uint8List.fromList(resp.payload));
    final itemMap = _unpackMap(u);
    if (itemMap.isEmpty) return null;

    final entry = DiaryEntryDto.fromMap(itemMap);
    final current = state.valueOrNull ?? [];
    state = AsyncData([entry, ...current]);
    return entry;
  }

  Future<void> deleteEntry(String entryId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != entryId).toList());

    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final p = Packer()
        ..packMapLength(1)
        ..packString('entry_id')
        ..packString(entryId);
      await hbp.send(HbpFrame.request('shua.diary', 'entry.delete', p.takeBytes()));
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

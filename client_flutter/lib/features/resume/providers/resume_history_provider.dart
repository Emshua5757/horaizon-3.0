import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';

import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../resume_history_item_dto.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final resumeHistoryProvider =
    AsyncNotifierProvider<ResumeHistoryNotifier, List<ResumeHistoryItemDto>>(
  ResumeHistoryNotifier.new,
);

/// Track the currently selected history item for the PDF viewer.
final selectedHistoryItemProvider =
    StateProvider<ResumeHistoryItemDto?>((ref) => null);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Fetches and caches the resume PDF compile history list.
///
/// Invalidated automatically after a successful compile via
/// [resumeCompileProvider].
///
/// Time: O(n) for n history rows (capped at 50 on the backend).
/// Space: O(n).
class ResumeHistoryNotifier
    extends AsyncNotifier<List<ResumeHistoryItemDto>> {
  @override
  Future<List<ResumeHistoryItemDto>> build() async {
    final hbp = await ref.watch(hbpClientProvider.future);
    final frame = HbpFrame.request('shua.resume', 'history.list', []);
    final resp = await hbp.send(frame);
    return _decodeHistory(resp);
  }

  /// Force a refresh (called after compile succeeds).
  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Decode helper
// ---------------------------------------------------------------------------

List<ResumeHistoryItemDto> _decodeHistory(HbpFrame frame) {
  if (frame.payload.isEmpty) return [];
  try {
    final u = Unpacker(Uint8List.fromList(frame.payload));
    final topLen = u.unpackMapLength();

    for (var i = 0; i < topLen; i++) {
      final key = u.unpackString();
      if (key == 'items') {
        final listLen = u.unpackListLength();
        final items = <ResumeHistoryItemDto>[];
        for (var j = 0; j < listLen; j++) {
          final itemLen = u.unpackMapLength();
          final m = <dynamic, dynamic>{};
          for (var k = 0; k < itemLen; k++) {
            final mk = _unpackAny(u);
            final mv = _unpackAny(u);
            if (mk != null) m[mk] = mv;
          }
          items.add(ResumeHistoryItemDto.fromMap(m));
        }
        return items;
      } else {
        // Skip value for this key
        _unpackAny(u);
      }
    }
    return [];
  } catch (_) {
    return [];
  }
}

dynamic _unpackAny(Unpacker u) {
  try {
    return u.unpackString();
  } catch (_) {}
  try {
    return u.unpackInt();
  } catch (_) {}
  try {
    return u.unpackDouble();
  } catch (_) {}
  try {
    return u.unpackBool();
  } catch (_) {}
  try {
    final len = u.unpackMapLength();
    final m = <dynamic, dynamic>{};
    for (var i = 0; i < len; i++) {
      final k = _unpackAny(u);
      final v = _unpackAny(u);
      if (k != null) m[k] = v;
    }
    return m;
  } catch (_) {}
  try {
    final len = u.unpackListLength();
    return List.generate(len, (_) => _unpackAny(u));
  } catch (_) {}
  return null;
}

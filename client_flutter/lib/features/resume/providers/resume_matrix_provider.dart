import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import 'package:uuid/uuid.dart';

import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../resume_matrix_dto.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Provider declaration
// ---------------------------------------------------------------------------

final resumeMatrixProvider =
    AsyncNotifierProvider<ResumeMatrixNotifier, ResumeMatrixDto>(
  ResumeMatrixNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the ResumeMatrix state: fetch on build, optimistic CRUD mutations.
///
/// Data flow: Widget → provider method → HBP v2 RPC (shua.resume.*).
///
/// Time Complexity: O(n) on matrix size.  Space: O(n) for cached state.
class ResumeMatrixNotifier extends AsyncNotifier<ResumeMatrixDto> {
  @override
  Future<ResumeMatrixDto> build() async {
    final hbp = await ref.watch(hbpClientProvider.future);
    // matrix.get has no request payload — empty bytes
    final frame = HbpFrame.request('shua.resume', 'matrix.get', []);
    final resp = await hbp.send(frame);
    return _decodeMatrix(resp);
  }

  /// Upsert a section item with optimistic local update.
  ///
  /// Immediately updates local state, then fires background RPC.
  /// On RPC error, invalidates self to revert to last good server state.
  Future<void> upsertSection(
      String section, Map<String, dynamic> item) async {
    // Optimistic update
    final current = state.requireValue;
    state = AsyncData(_applyUpsert(current, section, item));

    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final payload = _encodeMsgpack({
        'section': section,
        'action': 'upsert',
        'item': item,
      });
      final frame = HbpFrame.request('shua.resume', 'matrix.update', payload);
      final resp = await hbp.send(frame);
      if (resp.isError) ref.invalidateSelf(); // Revert on server error
    } catch (_) {
      ref.invalidateSelf(); // Revert on network error
    }
  }

  /// Delete a section item optimistically.
  Future<void> deleteItem(String section, String id) async {
    final current = state.requireValue;
    state = AsyncData(_applyDelete(current, section, id));

    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final payload = _encodeMsgpack({
        'section': section,
        'action': 'delete',
        'id': id,
      });
      final frame = HbpFrame.request('shua.resume', 'matrix.update', payload);
      final resp = await hbp.send(frame);
      if (resp.isError) ref.invalidateSelf();
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ResumeMatrixDto _applyUpsert(
      ResumeMatrixDto matrix, String section, Map<String, dynamic> item) {
    final id = item['id'] as String? ?? '';
    switch (section) {
      case 'basics':
        return matrix.copyWith(
            basics: BasicsDto.fromMap(item));
      case 'work':
        final list = List<WorkItemDto>.from(matrix.work);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = WorkItemDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(work: list);
      case 'education':
        final list = List<EducationDto>.from(matrix.education);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = EducationDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(education: list);
      case 'projects':
        final list = List<ProjectItemDto>.from(matrix.projects);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = ProjectItemDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(projects: list);
      case 'skills':
        final list = List<SkillDto>.from(matrix.skills);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = SkillDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(skills: list);
      case 'certificates':
        final list = List<CertificateDto>.from(matrix.certificates);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = CertificateDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(certificates: list);
      case 'awards':
        final list = List<AwardDto>.from(matrix.awards);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = AwardDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(awards: list);
      default:
        return matrix;
    }
  }

  ResumeMatrixDto _applyDelete(
      ResumeMatrixDto matrix, String section, String id) {
    switch (section) {
      case 'work':
        return matrix.copyWith(
            work: matrix.work.where((e) => e.id != id).toList());
      case 'education':
        return matrix.copyWith(
            education: matrix.education.where((e) => e.id != id).toList());
      case 'projects':
        return matrix.copyWith(
            projects: matrix.projects.where((e) => e.id != id).toList());
      case 'skills':
        return matrix.copyWith(
            skills: matrix.skills.where((e) => e.id != id).toList());
      case 'certificates':
        return matrix.copyWith(
            certificates:
                matrix.certificates.where((e) => e.id != id).toList());
      case 'awards':
        return matrix.copyWith(
            awards: matrix.awards.where((e) => e.id != id).toList());
      default:
        return matrix;
    }
  }
}

// ---------------------------------------------------------------------------
// Decode helpers
// ---------------------------------------------------------------------------

/// Decode matrix from HBP v2 response frame.
/// The backend sends payload as base64-encoded msgpack in the JSON frame.
/// HbpFrame.decode() extracts the raw msgpack bytes already.
ResumeMatrixDto _decodeMatrix(HbpFrame frame) {
  if (frame.payload.isEmpty) return const ResumeMatrixDto();
  try {
    final u = Unpacker(Uint8List.fromList(frame.payload));
    final map = _unpackMap(u);
    return ResumeMatrixDto.fromMap(map);
  } catch (e) {
    // Fallback: try JSON decode (useful in dev/mock)
    try {
      final decoded = utf8.decode(frame.payload);
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return ResumeMatrixDto.fromMap(json);
    } catch (_) {
      return const ResumeMatrixDto();
    }
  }
}

/// Encode a string-keyed map as msgpack bytes for HBP v2 request payload.
List<int> _encodeMsgpack(Map<String, dynamic> map) {
  final p = Packer();
  _packMap(p, map);
  return p.takeBytes();
}

void _packMap(Packer p, Map<String, dynamic> map) {
  p.packMapLength(map.length);
  for (final entry in map.entries) {
    p.packString(entry.key);
    _packValue(p, entry.value);
  }
}

void _packValue(Packer p, dynamic value) {
  if (value == null) {
    p.packNull();
  } else if (value is bool) {
    p.packBool(value);
  } else if (value is int) {
    p.packInt(value);
  } else if (value is double) {
    p.packDouble(value);
  } else if (value is String) {
    p.packString(value);
  } else if (value is List) {
    p.packListLength(value.length);
    for (final item in value) {
      _packValue(p, item);
    }
  } else if (value is Map<String, dynamic>) {
    _packMap(p, value);
  } else {
    p.packString(value.toString());
  }
}

Map<dynamic, dynamic> _unpackMap(Unpacker u) {
  final len = u.unpackMapLength();
  final map = <dynamic, dynamic>{};
  for (var i = 0; i < len; i++) {
    final key = _unpackAny(u);
    final val = _unpackAny(u);
    if (key != null) map[key] = val;
  }
  return map;
}

dynamic _unpackAny(Unpacker u) {
  try {
    final s = u.unpackString();
    return s;
  } catch (_) {}
  try {
    final i = u.unpackInt();
    return i;
  } catch (_) {}
  try {
    final d = u.unpackDouble();
    return d;
  } catch (_) {}
  try {
    final b = u.unpackBool();
    return b;
  } catch (_) {}
  try {
    return _unpackMap(u);
  } catch (_) {}
  try {
    final len = u.unpackListLength();
    return List.generate(len, (_) => _unpackAny(u));
  } catch (_) {}
  return null;
}

/// Generates a fresh blank WorkItemDto with a new UUID.
WorkItemDto newBlankWorkItem() => WorkItemDto(id: _uuid.v4());

/// Generates a fresh blank ProjectItemDto with a new UUID.
ProjectItemDto newBlankProjectItem() => ProjectItemDto(id: _uuid.v4());

/// Generates a fresh blank EducationDto with a new UUID.
EducationDto newBlankEducation() => EducationDto(id: _uuid.v4());

/// Generates a fresh blank SkillDto with a new UUID.
SkillDto newBlankSkill() => SkillDto(id: _uuid.v4());

/// Generates a fresh blank CertificateDto with a new UUID.
CertificateDto newBlankCertificate() => CertificateDto(id: _uuid.v4());

/// Generates a fresh blank AwardDto with a new UUID.
AwardDto newBlankAward() => AwardDto(id: _uuid.v4());

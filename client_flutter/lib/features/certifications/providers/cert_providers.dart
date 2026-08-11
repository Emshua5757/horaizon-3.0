import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../models/cert_dtos.dart';

final certDashboardProvider = FutureProvider<CertDashboardDto>((ref) async {
  final hbp = await ref.watch(hbpClientProvider.future);
  final p = Packer()..packMapLength(0);
  final resp = await hbp.send(HbpFrame.request('shua.diary', 'cert.dashboard', p.takeBytes()));
  if (resp.payload.isEmpty) {
    return const CertDashboardDto(totalCerts: 0, byStatus: {}, totalInvestedPhp: 0, roadmap: []);
  }
  final map = _unpackMap(Unpacker(Uint8List.fromList(resp.payload)));
  return CertDashboardDto.fromMap(map);
});

final certRoadmapProvider = FutureProvider<List<CertEntryDto>>((ref) async {
  final hbp = await ref.watch(hbpClientProvider.future);
  final p = Packer()..packMapLength(0);
  final resp = await hbp.send(HbpFrame.request('shua.diary', 'cert.roadmap', p.takeBytes()));
  if (resp.payload.isEmpty) return [];

  try {
    final u = Unpacker(Uint8List.fromList(resp.payload));
    final len = u.unpackListLength();
    final list = <CertEntryDto>[];
    for (var i = 0; i < len; i++) {
      final map = _unpackMap(u);
      if (map.isNotEmpty) list.add(CertEntryDto.fromMap(map));
    }
    return list;
  } catch (_) {
    return [];
  }
});

final certInvestmentsProvider = FutureProvider<List<CertInvestmentDto>>((ref) async {
  final hbp = await ref.watch(hbpClientProvider.future);
  final p = Packer()..packMapLength(0);
  final resp = await hbp.send(HbpFrame.request('shua.diary', 'cert.investment.list', p.takeBytes()));
  if (resp.payload.isEmpty) return [];

  try {
    final u = Unpacker(Uint8List.fromList(resp.payload));
    final len = u.unpackListLength();
    final list = <CertInvestmentDto>[];
    for (var i = 0; i < len; i++) {
      final map = _unpackMap(u);
      if (map.isNotEmpty) list.add(CertInvestmentDto.fromMap(map));
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

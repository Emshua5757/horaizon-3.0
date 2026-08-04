import 'dart:typed_data';
import 'package:messagepack/messagepack.dart';

/// Response DTO for shua.resume.compile HBP v2 RPC.
///
/// The backend encodes the response with index-keyed msgpack:
///   1 → exhibit_id (str)
///   2 → pdf_url    (str)
///   3 → duration_ms (u32)
///   4 → tailor_score (f32?) — null if not tailored
///
/// Time: O(1) | Space: O(1)
class ResumeCompileResponseDto {
  final String exhibitId;
  final String vaultUrl;
  final int durationMs;
  final double? tailorScore;

  const ResumeCompileResponseDto({
    required this.exhibitId,
    required this.vaultUrl,
    required this.durationMs,
    this.tailorScore,
  });

  /// Decode from raw msgpack bytes (the `p` field of the HBP frame, after
  /// base64-decoding by the caller).
  factory ResumeCompileResponseDto.fromMsgpack(List<int> bytes) {
    final u = Unpacker(Uint8List.fromList(bytes));
    final len = u.unpackMapLength();

    String exhibitId = '';
    String vaultUrl = '';
    int durationMs = 0;
    double? tailorScore;

    for (var i = 0; i < len; i++) {
      // Keys may be integer indices OR strings — try both.
      dynamic key;
      try {
        key = u.unpackInt();
      } catch (_) {
        try {
          key = u.unpackString();
        } catch (_) {
          break;
        }
      }

      switch (key) {
        case 1:
        case '1':
          exhibitId = u.unpackString() ?? '';
        case 2:
        case '2':
          vaultUrl = u.unpackString() ?? '';
        case 3:
        case '3':
          durationMs = u.unpackInt() ?? 0;
        case 4:
        case '4':
          try {
            final d = u.unpackDouble();
            tailorScore = d;
          } catch (_) {
            // nil / absent — skip
            u.unpackString(); // consume nil token
          }
        default:
          // Unknown key — consume value and skip
          try {
            u.unpackString();
          } catch (_) {
            try {
              u.unpackInt();
            } catch (_) {}
          }
      }
    }

    return ResumeCompileResponseDto(
      exhibitId: exhibitId,
      vaultUrl: vaultUrl,
      durationMs: durationMs,
      tailorScore: tailorScore,
    );
  }
}

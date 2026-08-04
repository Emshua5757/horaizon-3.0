import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';

import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../resume_compile_response_dto.dart';
import 'resume_history_provider.dart';

// ---------------------------------------------------------------------------
// Compile state machine
// ---------------------------------------------------------------------------

sealed class ResumeCompileState {
  const ResumeCompileState();
}

class CompileIdle extends ResumeCompileState {
  const CompileIdle();
}

class CompileInProgress extends ResumeCompileState {
  final bool aiEnhance;
  const CompileInProgress({this.aiEnhance = false});
}

class CompileSuccess extends ResumeCompileState {
  final ResumeCompileResponseDto result;
  const CompileSuccess(this.result);
}

class CompileError extends ResumeCompileState {
  final String message;
  const CompileError(this.message);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final resumeCompileProvider =
    StateNotifierProvider<ResumeCompileNotifier, ResumeCompileState>(
  (ref) => ResumeCompileNotifier(ref),
);

/// Simple providers for compile screen local state.
final jdTextProvider = StateProvider<String>((ref) => '');
final liveJaccardScoreProvider = StateProvider<double>((ref) => 0.0);
final selectedTemplateProvider = StateProvider<String>((ref) => 'default');
final aiEnhanceProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// State machine for the PDF compile pipeline.
///
/// States: idle → compiling → success | error → idle.
///
/// Time: O(network) bounded by Typst + optional Ollama on Pi 5.
/// Space: O(pdf_size) transient during compile.
class ResumeCompileNotifier extends StateNotifier<ResumeCompileState> {
  final Ref _ref;

  ResumeCompileNotifier(this._ref) : super(const CompileIdle());

  /// Dispatch shua.resume.compile RPC with 120s timeout.
  ///
  /// On success: transitions to [CompileSuccess] and triggers history refresh.
  /// On error:  transitions to [CompileError] with the error message.
  Future<void> compile({
    required String template,
    String jobDesc = '',
    bool tailor = false,
    bool aiEnhance = false,
  }) async {
    state = CompileInProgress(aiEnhance: aiEnhance);

    try {
      final hbp = await _ref.read(hbpClientProvider.future);
      final payload = _buildCompilePayload(
        template: template,
        jobDesc: jobDesc,
        tailor: tailor,
        aiEnhance: aiEnhance,
      );
      final frame =
          HbpFrame.request('shua.resume', 'compile', payload);
      final resp = await hbp.send(
        frame,
        timeout: const Duration(seconds: 120),
      );

      if (resp.isError) {
        state = CompileError(resp.error ?? 'Compile failed');
        return;
      }

      final dto = ResumeCompileResponseDto.fromMsgpack(resp.payload);
      state = CompileSuccess(dto);

      // Refresh history list after successful compile
      _ref.invalidate(resumeHistoryProvider);
    } catch (e) {
      state = CompileError(e.toString());
    }
  }

  /// Reset to idle — called after the overlay is dismissed.
  void reset() => state = const CompileIdle();

  // ── Payload builder ────────────────────────────────────────────────────────

  /// Encode compile request as string-keyed msgpack.
  /// Go handler decodes via decodeMsgpackOrJSON which accepts both string and
  /// integer keys; we use string keys matching the json struct tags.
  List<int> _buildCompilePayload({
    required String template,
    required String jobDesc,
    required bool tailor,
    required bool aiEnhance,
  }) {
    final p = Packer();
    p.packMapLength(5);
    p.packString('matrix_id'); p.packString('shua');
    p.packString('template');  p.packString(template);
    p.packString('job_desc');  p.packString(jobDesc);
    p.packString('tailor');    p.packBool(tailor);
    p.packString('ai_enhance'); p.packBool(aiEnhance);
    return p.takeBytes();
  }
}

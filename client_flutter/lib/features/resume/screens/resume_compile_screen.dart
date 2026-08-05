import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hbp/hbp_client.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../providers/resume_compile_provider.dart';
import '../providers/resume_matrix_provider.dart';
import '../utils/jaccard_dart.dart';
import '../widgets/compile_progress_overlay.dart';
import '../widgets/jaccard_score_gauge.dart';
import '../widgets/template_picker.dart';

/// AI Tailoring & Compile screen.
///
/// Layout (top to bottom):
/// 1. Job description TextField (multiline, 400ms debounce → Jaccard)
/// 2. JaccardScoreGauge (animated arc, client-side live score)
/// 3. TemplatePicker (Default / Modern / Minimalist)
/// 4. AI Enhancement SwitchListTile
/// 5. Compile PDF ElevatedButton
/// 6. Last compile result card (if cached)
class ResumeCompileScreen extends ConsumerStatefulWidget {
  /// Called when compile succeeds to navigate to History tab.
  final VoidCallback onCompileSuccess;

  const ResumeCompileScreen({super.key, required this.onCompileSuccess});

  @override
  ConsumerState<ResumeCompileScreen> createState() =>
      _ResumeCompileScreenState();
}

class _ResumeCompileScreenState extends ConsumerState<ResumeCompileScreen> {
  final _jdController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _jdController.addListener(_onJdChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _jdController.dispose();
    super.dispose();
  }

  void _onJdChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final jd = _jdController.text;
      ref.read(jdTextProvider.notifier).state = jd;

      if (jd.trim().isEmpty) {
        ref.read(liveJaccardScoreProvider.notifier).state = 0.0;
        return;
      }

      final matrix = ref.read(resumeMatrixProvider).valueOrNull;
      if (matrix == null) return;

      final score = scoreResumeAgainstJd(matrix, jd);
      ref.read(liveJaccardScoreProvider.notifier).state = score;
    });
  }

  Future<void> _compile() async {
    final jd = ref.read(jdTextProvider);
    final template = ref.read(selectedTemplateProvider);
    final aiEnhance = ref.read(aiEnhanceProvider);
    final aiModel = ref.read(selectedAiModelProvider);
    final rawTarget = ref.read(selectedAiOffloadTargetProvider);
    final tailor = jd.trim().isNotEmpty;

    final String aiTarget = switch (rawTarget) {
      'rpi5' => 'http://127.0.0.1:11434',
      'windows' => 'http://192.168.254.110:11434',
      _ => '',
    };

    await ref.read(resumeCompileProvider.notifier).compile(
          template: template,
          jobDesc: jd,
          tailor: tailor,
          aiEnhance: aiEnhance,
          aiModel: aiModel,
          aiOffloadTarget: aiTarget,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final connState = ref.watch(hbpConnectionStateProvider).valueOrNull ??
        HbpConnectionState.disconnected;
    final isOffline = connState != HbpConnectionState.connected;

    final compileState = ref.watch(resumeCompileProvider);
    final jaccardScore = ref.watch(liveJaccardScoreProvider);
    final template = ref.watch(selectedTemplateProvider);
    final aiEnhance = ref.watch(aiEnhanceProvider);
    final selectedModel = ref.watch(selectedAiModelProvider);
    final selectedTarget = ref.watch(selectedAiOffloadTargetProvider);

    // Navigate to history on success
    ref.listen(resumeCompileProvider, (_, next) {
      if (next is CompileSuccess) {
        widget.onCompileSuccess();
        ref.read(resumeCompileProvider.notifier).reset();
      }
    });

    final CompileInProgress? inProgress = compileState is CompileInProgress
        ? compileState
        : null;
    final isCompiling = inProgress != null;
    final lastSuccess =
        compileState is CompileSuccess ? compileState.result : null;

    return Stack(
      children: [
        // ── Main scroll content ──────────────────────────────────────────
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isOffline)
                _offlineBanner(),

              // 1. Job description input
              Text('Job Description',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _jdController,
                maxLines: 7,
                decoration: InputDecoration(
                  hintText:
                      'Paste the job description here to analyse keyword match...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                ),
              ),

              // 2. Jaccard gauge
              const SizedBox(height: 24),
              Center(child: JaccardScoreGauge(score: jaccardScore)),

              // 3. Template picker
              const SizedBox(height: 24),
              Text('Template',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TemplatePicker(
                selected: template,
                onSelected: (t) =>
                    ref.read(selectedTemplateProvider.notifier).state = t,
              ),

              // 4. AI enhancement toggle & panel
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: aiEnhance ? cs.primary : cs.outlineVariant,
                    width: aiEnhance ? 1.5 : 1,
                  ),
                ),
                color: aiEnhance
                    ? cs.primaryContainer.withValues(alpha: 0.15)
                    : cs.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('Enable AI Enhancement',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                            'Rewrites bullet points & optimizes keywords for the job description.'),
                        value: aiEnhance,
                        onChanged: isOffline
                            ? null
                            : (v) => ref
                                .read(aiEnhanceProvider.notifier)
                                .state = v,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (aiEnhance) ...[
                        const Divider(height: 20),
                        if (_jdController.text.trim().isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 16, color: cs.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'General Polish Mode — Paste a job description above for target-tailored enhancement.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // ── Execution Node Target ─────────────────────────────
                        Text('AI Execution Node',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 6),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'auto',
                              label: Text('Auto'),
                              icon: Icon(Icons.auto_awesome_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: 'rpi5',
                              label: Text('RPi 5'),
                              icon: Icon(Icons.developer_board_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: 'windows',
                              label: Text('Windows Host'),
                              icon: Icon(Icons.laptop_mac_rounded, size: 16),
                            ),
                          ],
                          selected: {selectedTarget},
                          onSelectionChanged: (set) {
                            if (set.isNotEmpty) {
                              ref
                                  .read(selectedAiOffloadTargetProvider.notifier)
                                  .state = set.first;
                            }
                          },
                          showSelectedIcon: false,
                        ),
                        const SizedBox(height: 12),
                        // ── Model Selection ─────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ollama Model',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedModel,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'qwen3.5:4b',
                                        child: Text('qwen3.5:4b (Recommended)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'qwen3.5:2b',
                                        child: Text('qwen3.5:2b (Fast / Pi 5)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'qwen2.5-coder:7b',
                                        child: Text('qwen2.5-coder:7b (Detailed)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'llama3.1:8b',
                                        child: Text('llama3.1:8b (High quality)'),
                                      ),
                                    ],
                                    onChanged: (m) {
                                      if (m != null) {
                                        ref
                                            .read(selectedAiModelProvider
                                                .notifier)
                                            .state = m;
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 5. Compile button
              const SizedBox(height: 16),
              Tooltip(
                message: isOffline ? 'Connect to Pi 5 to compile' : '',
                child: FilledButton.icon(
                  onPressed: isOffline || isCompiling ? null : _compile,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(aiEnhance
                      ? 'Compile PDF with AI ($selectedModel)'
                      : 'Compile PDF'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                ),
              ),

              // Error state
              if (compileState is CompileError) ...[
                const SizedBox(height: 12),
                Card(
                  color: cs.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: cs.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text((compileState).message,
                              style: TextStyle(color: cs.onErrorContainer)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 6. Last compile result card
              if (lastSuccess != null) ...[
                const SizedBox(height: 16),
                _LastResultCard(
                  exhibitId: lastSuccess.exhibitId,
                  durationMs: lastSuccess.durationMs,
                  tailorScore: lastSuccess.tailorScore,
                  onTap: widget.onCompileSuccess,
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),

        // ── Compile overlay ────────────────────────────────────────────────
        if (isCompiling)
          CompileProgressOverlay(
            aiEnhance: inProgress.aiEnhance,
            onCancel: () =>
                ref.read(resumeCompileProvider.notifier).reset(),
          ),
      ],
    );
  }

  Widget _offlineBanner() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: MaterialBanner(
          content: const Text(
              'Pi 5 offline — Resume data unavailable'),
          backgroundColor: const Color(0xFFFFF3E0),
          leading: const Icon(Icons.wifi_off_rounded,
              color: Color(0xFFFFA000)),
          actions: [
            TextButton(onPressed: () {}, child: const Text('Dismiss')),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Last result card
// ---------------------------------------------------------------------------

class _LastResultCard extends StatelessWidget {
  final String exhibitId;
  final int durationMs;
  final double? tailorScore;
  final VoidCallback onTap;

  const _LastResultCard({
    required this.exhibitId,
    required this.durationMs,
    required this.tailorScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = tailorScore != null
        ? ' — Match: ${(tailorScore! * 100).round()}%'
        : '';
    final dur = '${(durationMs / 1000).toStringAsFixed(1)}s';

    return Card(
      color: cs.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.check_circle_rounded, color: cs.primary),
        title: const Text('PDF compiled successfully'),
        subtitle: Text('Duration: $dur$score'),
        trailing:
            Icon(Icons.arrow_forward_rounded, color: cs.primary),
        onTap: onTap,
      ),
    );
  }
}

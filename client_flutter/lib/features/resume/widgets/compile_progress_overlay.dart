import 'dart:async';
import 'package:flutter/material.dart';

/// Full-screen overlay shown during PDF compilation on Pi 5.
///
/// - Shimmer card animation
/// - Live elapsed time [Ticker]
/// - Optional AI enhancement text when [aiEnhance] is true
/// - Cancel button: dismisses overlay locally only (compile continues on Pi 5)
class CompileProgressOverlay extends StatefulWidget {
  final bool aiEnhance;
  final VoidCallback onCancel;

  const CompileProgressOverlay({
    super.key,
    required this.aiEnhance,
    required this.onCancel,
  });

  @override
  State<CompileProgressOverlay> createState() => _CompileProgressOverlayState();
}

class _CompileProgressOverlayState extends State<CompileProgressOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  int _elapsedSeconds = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Shimmer card ───────────────────────────────────────
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) {
                      final gradient = LinearGradient(
                        colors: [
                          cs.surfaceContainerHighest,
                          cs.surfaceContainerHigh,
                          cs.surfaceContainerHighest,
                        ],
                        stops: [
                          (_shimmer.value - 0.3).clamp(0.0, 1.0),
                          _shimmer.value.clamp(0.0, 1.0),
                          (_shimmer.value + 0.3).clamp(0.0, 1.0),
                        ],
                      );
                      return Container(
                        width: 240,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) {
                      final gradient = LinearGradient(
                        colors: [
                          cs.surfaceContainerHighest,
                          cs.surfaceContainerHigh,
                          cs.surfaceContainerHighest,
                        ],
                        stops: [
                          (_shimmer.value - 0.3).clamp(0.0, 1.0),
                          _shimmer.value.clamp(0.0, 1.0),
                          (_shimmer.value + 0.3).clamp(0.0, 1.0),
                        ],
                      );
                      return Container(
                        width: 180,
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Status text ────────────────────────────────────────
                  Icon(Icons.description_rounded,
                      size: 40, color: cs.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Compiling on Pi 5...',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elapsed: ${_elapsedSeconds}s',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                  ),

                  if (widget.aiEnhance) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: cs.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          'AI enhancement in progress...',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: cs.tertiary),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Cancel button ──────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Dismiss'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compile continues on Pi 5 — result will arrive when done.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

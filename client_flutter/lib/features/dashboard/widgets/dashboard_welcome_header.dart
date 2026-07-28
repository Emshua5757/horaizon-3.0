import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_semantic_palette.dart';
import '../../governor/governor_provider.dart';

/// Refined Welcome Header dynamically adapting to Theme Preset, supporting responsive wrapping.
class DashboardWelcomeHeader extends ConsumerWidget {
  const DashboardWelcomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = theme.extension<AppSemanticPalette>();

    final successColor = semantic?.success ?? cs.primary;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome back, Joshua',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Consumer(
              builder: (context, ref, child) {
                final statusAsync = ref.watch(governorStatusProvider);
                final uptimeS = statusAsync.valueOrNull?.uptimeS;
                final String uptimeText;
                if (uptimeS != null && uptimeS > 0) {
                  final days = uptimeS ~/ 86400;
                  final hours = (uptimeS % 86400) ~/ 3600;
                  final mins = (uptimeS % 3600) ~/ 60;
                  final secs = uptimeS % 60;
                  if (days > 0) {
                    uptimeText = 'Uptime: ${days}d ${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m';
                  } else if (hours > 0) {
                    uptimeText = 'Uptime: ${hours}h ${mins.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
                  } else {
                    uptimeText = 'Uptime: ${mins}m ${secs.toString().padLeft(2, '0')}s';
                  }
                } else {
                  uptimeText = 'Uptime: Live';
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: successColor,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      uptimeText,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),

        // Sleek Telemetry Refresh Pill Button
        InkWell(
          onTap: () => ref.read(governorStatusProvider.notifier).refresh(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cs.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: cs.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Refresh',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

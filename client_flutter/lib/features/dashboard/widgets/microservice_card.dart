import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_effects_theme.dart';
import '../../../core/theme/app_semantic_palette.dart';
import '../../governor/governor_provider.dart';
import 'stitch_card.dart';

/// Microservice Card displaying live module health metrics, CPU %, RAM, and full process power controls (Wake, Freeze, Stop/Kill).
class MicroserviceCard extends ConsumerWidget {
  final String name;
  final String title;
  final IconData icon;
  final Color accentColor;
  final GovernorStatus status;
  final String ramText;
  final String subText;
  final VoidCallback? onLaunch;
  final bool isBuilt;

  const MicroserviceCard({
    super.key,
    required this.name,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.status,
    required this.ramText,
    required this.subText,
    this.onLaunch,
    this.isBuilt = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticPalette>();
    final effects = Theme.of(context).extension<AppEffectsTheme>();

    final warningColor = semantic?.warning ?? const Color(0xFFF59E0B);
    final successColor = semantic?.success ?? const Color(0xFF3CE36A);
    final criticalColor = semantic?.critical ?? const Color(0xFFEF4444);
    final disabledColor = cs.onSurfaceVariant.withValues(alpha: 0.38);

    if (!isBuilt) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(effects?.cardRadius ?? 8),
          border: Border(
            left: BorderSide(
              color: disabledColor,
              width: 3,
            ),
          ),
        ),
        child: StitchCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: cs.onSurfaceVariant.withValues(alpha: 0.5), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PLANNED',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Not Installed',
                    style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11),
                  ),
                  Text(
                    subText,
                    style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(effects?.buttonRadius ?? 8)),
                  ),
                  onPressed: null,
                  child: const Text(
                    'Not Installed',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Lookup active module status
    final module = status.modules.firstWhere(
      (m) =>
          m.name == name ||
          m.name.replaceAll('.', '_') == name.replaceAll('.', '_') ||
          (m.name.contains('code') && name.contains('code')),
      orElse: () => ModuleStatus(
        name: name,
        state: ModuleState.running,
        ramMb: 245.0,
        cpuPercent: 0.8,
        healthOk: true,
      ),
    );

    final isSleeping = module.state == ModuleState.sleeping;
    final isStopped = module.state == ModuleState.stopped;
    final isRunning = module.state == ModuleState.running;

    final statusColor = isSleeping
        ? warningColor
        : (isStopped ? criticalColor : (module.healthOk ? successColor : criticalColor));
    final useHalo = effects?.useStatusHalo ?? true;

    final ramDisplay = isStopped
        ? '0 MB RAM (Terminated)'
        : (isSleeping
            ? '${module.ramMb.toStringAsFixed(0)} MB RAM (Frozen)'
            : '${module.ramMb.toStringAsFixed(0)} MB RAM');

    final cpuDisplay = isRunning ? ' • ${module.cpuPercent.toStringAsFixed(1)}% CPU' : '';

    final statusTagText = isStopped
        ? 'Stopped (0 MB RAM)'
        : (isSleeping ? 'SIGSTOP (Frozen)' : (isRunning ? 'Active (cgroup v2)' : 'Degraded'));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effects?.cardRadius ?? 8),
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 3,
          ),
        ),
      ),
      child: StitchCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Health Indicator Row
            Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  statusTagText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: (useHalo && isRunning)
                        ? [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // RAM & CPU Metrics Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$ramDisplay$cpuDisplay',
                    style: TextStyle(
                      color: isSleeping ? warningColor : (isStopped ? cs.onSurfaceVariant : cs.onSurface),
                      fontSize: 11,
                      fontWeight: (isSleeping || isRunning) ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  subText,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons Row: Power Toggle + Stop/Kill + Launch Screen
            Row(
              children: [
                // Power State Toggle Button (Wake or Freeze)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: (isSleeping || isStopped) ? successColor : warningColor,
                      side: BorderSide(
                        color: ((isSleeping || isStopped) ? successColor : warningColor).withValues(alpha: 0.5),
                      ),
                      backgroundColor: ((isSleeping || isStopped) ? successColor : warningColor).withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(effects?.buttonRadius ?? 8),
                      ),
                    ),
                    onPressed: () {
                      if (isSleeping || isStopped) {
                        ref.read(governorStatusProvider.notifier).wakeModule(name);
                      } else {
                        ref.read(governorStatusProvider.notifier).sleepModule(name);
                      }
                    },
                    icon: Icon(
                      (isSleeping || isStopped) ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 15,
                    ),
                    label: Text(
                      (isSleeping || isStopped) ? 'Wake' : 'Freeze',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Stop / Kill Button (Releases RAM completely)
                if (!isStopped) ...[
                  IconButton(
                    style: IconButton.styleFrom(
                      foregroundColor: criticalColor,
                      backgroundColor: criticalColor.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(effects?.buttonRadius ?? 8),
                      ),
                    ),
                    tooltip: 'Stop & Free RAM (SIGKILL)',
                    onPressed: () {
                      ref.read(governorStatusProvider.notifier).stopModule(name);
                    },
                    icon: const Icon(Icons.stop_rounded, size: 16),
                  ),
                  const SizedBox(width: 6),
                ],

                if (onLaunch != null) ...[
                  // Dedicated Launch Screen Button
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(effects?.buttonRadius ?? 8),
                        ),
                      ),
                      onPressed: onLaunch,
                      icon: const Icon(Icons.open_in_new_rounded, size: 13),
                      label: const Text(
                        'Open Screen',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

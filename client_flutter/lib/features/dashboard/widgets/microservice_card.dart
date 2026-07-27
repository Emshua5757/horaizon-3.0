import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_effects_theme.dart';
import '../../../core/theme/app_semantic_palette.dart';
import '../../governor/governor_provider.dart';
import 'stitch_card.dart';

/// Microservice Card displaying live module health metrics, CPU %, RAM, and power controls
/// dynamically adapting to active Theme Preset and AppSemanticPalette.
class MicroserviceCard extends ConsumerWidget {
  final String name;
  final String title;
  final IconData icon;
  final Color accentColor;
  final GovernorStatus status;
  final String ramText;
  final String subText;
  final String buttonLabel;
  final VoidCallback onLaunch;
  final bool isSigstop;

  const MicroserviceCard({
    super.key,
    required this.name,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.status,
    required this.ramText,
    required this.subText,
    required this.buttonLabel,
    required this.onLaunch,
    this.isSigstop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticPalette>();
    final effects = Theme.of(context).extension<AppEffectsTheme>();

    final module = status.modules.firstWhere(
      (m) => m.name == name || m.name == name.replaceAll('.', '_'),
      orElse: () => ModuleStatus(
        name: name,
        state: isSigstop ? ModuleState.stopped : ModuleState.running,
        ramMb: isSigstop ? 0.0 : 115.0,
        cpuPercent: isSigstop ? 0.0 : 0.8,
        healthOk: !isSigstop,
      ),
    );
    final isRunning = module.state == ModuleState.running && !isSigstop;
    final isHealthy = module.healthOk && !isSigstop;

    final warningColor = semantic?.warning ?? const Color(0xFFF59E0B);
    final successColor = semantic?.success ?? const Color(0xFF3CE36A);
    final criticalColor = semantic?.critical ?? const Color(0xFFEF4444);

    final statusColor = isSigstop ? warningColor : (isHealthy ? successColor : criticalColor);

    final ramDisplay = module.ramMb > 0 ? '${module.ramMb.toStringAsFixed(0)} MB RAM' : ramText;
    final cpuDisplay = isRunning ? ' • ${module.cpuPercent.toStringAsFixed(1)}% CPU' : '';

    final useHalo = effects?.useStatusHalo ?? true;

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
                if (isSigstop) ...[
                  Text(
                    'SIGSTOP',
                    style: TextStyle(
                      color: warningColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: (useHalo && isHealthy)
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

            // RAM, CPU & Metrics details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$ramDisplay$cpuDisplay',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
                Text(
                  subText,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Launch / Wake Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSigstop ? warningColor : cs.onSurface,
                  side: BorderSide(
                    color: isSigstop ? warningColor.withValues(alpha: 0.5) : cs.outlineVariant,
                  ),
                  backgroundColor: isSigstop ? warningColor.withValues(alpha: 0.08) : cs.surface.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(effects?.buttonRadius ?? 8)),
                ),
                onPressed: () {
                  if (!isRunning) {
                    ref.read(governorStatusProvider.notifier).wakeModule(name);
                  }
                  onLaunch();
                },
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

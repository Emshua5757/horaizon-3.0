import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../governor/governor_provider.dart';
import 'stitch_card.dart';

/// Microservice Card displaying live module health metrics, CPU %, RAM, and power controls.
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

    final ramDisplay = module.ramMb > 0 ? '${module.ramMb.toStringAsFixed(0)} MB RAM' : ramText;
    final cpuDisplay = isRunning ? ' • ${module.cpuPercent.toStringAsFixed(1)}% CPU' : '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isSigstop ? const Color(0xFFF59E0B) : const Color(0xFF3CE36A),
            width: 3,
          ),
        ),
      ),
      child: StitchCard(
        borderColor: isSigstop
            ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
            : (isRunning ? const Color(0xFF3CE36A).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08)),
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
                    style: const TextStyle(
                      color: Color(0xFFD4E4FA),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Geist',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSigstop) ...[
                  const Text(
                    'SIGSTOP',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSigstop
                        ? const Color(0xFFF59E0B)
                        : (isHealthy ? const Color(0xFF3CE36A) : const Color(0xFFEF4444)),
                    boxShadow: isHealthy
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3CE36A).withValues(alpha: 0.6),
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
                  style: TextStyle(color: const Color(0xFFC8C5CB).withValues(alpha: 0.8), fontSize: 11, fontFamily: 'Geist'),
                ),
                Text(
                  subText,
                  style: TextStyle(color: const Color(0xFFC8C5CB).withValues(alpha: 0.8), fontSize: 11, fontFamily: 'Geist'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Launch / Wake Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSigstop ? const Color(0xFFF59E0B) : const Color(0xFFD4E4FA),
                  side: BorderSide(
                    color: isSigstop
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                  backgroundColor: isSigstop ? const Color(0xFFF59E0B).withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

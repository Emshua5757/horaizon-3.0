import 'package:flutter/material.dart';
import '../../../core/theme/app_semantic_palette.dart';
import '../../governor/governor_provider.dart';
import 'stitch_card.dart';

/// RPi5 Edge Node Hardware Telemetry Hero Card strictly matching Google Stitch layout
/// and dynamically adapting to active Theme Preset and AppSemanticPalette.
class HardwareTelemetryHero extends StatelessWidget {
  final GovernorStatus status;

  const HardwareTelemetryHero({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticPalette>();

    final usedRamGb = (status.totalRamMb / 1024.0).toStringAsFixed(1);
    final totalRamGb = (status.ramCeilingMb / 1024.0).toStringAsFixed(1);
    final ramRatio = status.ramCeilingMb > 0 ? status.totalRamMb / status.ramCeilingMb : 0.3;

    final successColor = semantic?.success ?? cs.primary;
    final infoColor = semantic?.info ?? cs.secondary;

    return StitchCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RPI5 EDGE NODE',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Hardware Telemetry',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.developer_board_rounded,
                  color: cs.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2x2 Telemetry Grid
          Row(
            children: [
              // CPU Load Box
              Expanded(
                child: _TelemetryBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CPU Load',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.trending_up_rounded, color: successColor, size: 14),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${status.cpuUsagePct.toStringAsFixed(0)}%',
                        style: TextStyle(color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (status.cpuUsagePct / 100.0).clamp(0.0, 1.0),
                          backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(successColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // System Memory Box
              Expanded(
                child: _TelemetryBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Memory',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: usedRamGb,
                              style: TextStyle(color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text: ' / $totalRamGb GB',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ramRatio.clamp(0.0, 1.0),
                          backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(infoColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // SoC Temp Box
              Expanded(
                child: _TelemetryBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SoC Temp',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${status.socTempC.toStringAsFixed(1)}°C',
                        style: TextStyle(color: successColor, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Tailscale Latency Box
              Expanded(
                child: _TelemetryBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tailscale Latency',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${status.tailscaleLatencyMs}ms',
                        style: TextStyle(color: infoColor, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 16),

          // Footer Sync Badge
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: successColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Last Backup: ${status.lastBackupTime}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelemetryBox extends StatelessWidget {
  final Widget child;

  const _TelemetryBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

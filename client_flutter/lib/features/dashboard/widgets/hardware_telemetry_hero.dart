import 'package:flutter/material.dart';
import '../../governor/governor_provider.dart';
import 'stitch_card.dart';

/// RPi5 Edge Node Hardware Telemetry Hero Card strictly matching Google Stitch layout.
class HardwareTelemetryHero extends StatelessWidget {
  final GovernorStatus status;

  const HardwareTelemetryHero({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final usedRamGb = (status.totalRamMb / 1024.0).toStringAsFixed(1);
    final totalRamGb = (status.ramCeilingMb / 1024.0).toStringAsFixed(1);
    final ramRatio = status.ramCeilingMb > 0 ? status.totalRamMb / status.ramCeilingMb : 0.3;

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
                      color: const Color(0xFFC8C5CB).withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Hardware Telemetry',
                    style: TextStyle(
                      color: Color(0xFFD4E4FA),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.developer_board_rounded,
                  color: Color(0xFF00E5FF),
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CPU Load',
                            style: TextStyle(color: Color(0xFFC8C5CB), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.trending_up_rounded, color: Color(0xFF3CE36A), size: 14),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${status.cpuUsagePct.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (status.cpuUsagePct / 100.0).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3CE36A)),
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
                      const Text(
                        'System Memory',
                        style: TextStyle(color: Color(0xFFC8C5CB), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: usedRamGb,
                              style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 22, fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text: ' / $totalRamGb GB',
                              style: TextStyle(color: const Color(0xFFC8C5CB).withValues(alpha: 0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ramRatio.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
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
                      const Text(
                        'SoC Temp',
                        style: TextStyle(color: Color(0xFFC8C5CB), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${status.socTempC.toStringAsFixed(1)}°C',
                        style: const TextStyle(color: Color(0xFF3CE36A), fontSize: 20, fontWeight: FontWeight.w700),
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
                      const Text(
                        'Tailscale Latency',
                        style: TextStyle(color: Color(0xFFC8C5CB), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${status.tailscaleLatencyMs}ms',
                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 20, fontWeight: FontWeight.w700),
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3CE36A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Last Backup: ${status.lastBackupTime}',
                  style: TextStyle(color: const Color(0xFFC8C5CB).withValues(alpha: 0.5), fontSize: 11),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

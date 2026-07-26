import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../governor/governor_provider.dart';

/// State-of-the-art native glassmorphic Dashboard matching Google Stitch designs.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(governorStatusProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: statusAsync.when(
        data: (status) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Joshua',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2DD4BF),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'System Uptime: 14d 06h 22m',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF)),
                  onPressed: () => ref.read(governorStatusProvider.notifier).refresh(),
                  tooltip: 'Refresh Telemetry',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Hero Row (Hardware Telemetry & AI Aggregator Cards)
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _HardwareTelemetryCard(status: status)),
                  const SizedBox(width: 16),
                  Expanded(child: _AiAggregatorCard(status: status)),
                ],
              )
            else ...[
              _HardwareTelemetryCard(status: status),
              const SizedBox(height: 16),
              _AiAggregatorCard(status: status),
            ],

            const SizedBox(height: 24),

            // Supervised Microservices Section Header
            Text(
              'SUPERVISED MICROSERVICES',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Microservices List / Grid
            if (isDesktop)
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _MicroserviceTile(
                    name: 'shua_diary',
                    title: 'shua_diary',
                    icon: Icons.book_outlined,
                    accentColor: const Color(0xFF2DD4BF),
                    status: status,
                    onLaunch: () => context.go('/diary'),
                  ),
                  _MicroserviceTile(
                    name: 'shua_code_viz',
                    title: 'shua_code_viz',
                    icon: Icons.code_rounded,
                    accentColor: const Color(0xFF6366F1),
                    status: status,
                    onLaunch: () => context.go('/code/topology'),
                  ),
                  _MicroserviceTile(
                    name: 'shua_resume',
                    title: 'shua_resume',
                    icon: Icons.description_outlined,
                    accentColor: const Color(0xFFF59E0B),
                    status: status,
                    onLaunch: () => context.go('/resume/editor'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _MicroserviceTile(
                    name: 'shua_diary',
                    title: 'shua_diary',
                    icon: Icons.book_outlined,
                    accentColor: const Color(0xFF2DD4BF),
                    status: status,
                    onLaunch: () => context.go('/diary'),
                  ),
                  const SizedBox(height: 10),
                  _MicroserviceTile(
                    name: 'shua_code_viz',
                    title: 'shua_code_viz',
                    icon: Icons.code_rounded,
                    accentColor: const Color(0xFF6366F1),
                    status: status,
                    onLaunch: () => context.go('/code/topology'),
                  ),
                  const SizedBox(height: 10),
                  _MicroserviceTile(
                    name: 'shua_resume',
                    title: 'shua_resume',
                    icon: Icons.description_outlined,
                    accentColor: const Color(0xFFF59E0B),
                    status: status,
                    onLaunch: () => context.go('/resume/editor'),
                  ),
                ],
              ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
        error: (err, _) => Center(
          child: Text('Error loading status: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

/// Hardware Telemetry Card strictly matching Stitch layout.
class _HardwareTelemetryCard extends StatelessWidget {
  final GovernorStatus status;

  const _HardwareTelemetryCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ramPct = (status.totalRamMb / status.ramCeilingMb).clamp(0.0, 1.0);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HARDWARE TELEMETRY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GaugeMetric(
                  label: 'CPU Load',
                  value: '${status.cpuUsagePct.toStringAsFixed(0)}%',
                  progress: status.cpuUsagePct / 100.0,
                  color: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GaugeMetric(
                  label: 'Memory',
                  value: '${(status.totalRamMb / 1024.0).toStringAsFixed(1)} / 7.1 GB',
                  progress: ramPct,
                  color: const Color(0xFF00E5FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ChipTile(
                  icon: Icons.thermostat_outlined,
                  label: 'SoC Temp',
                  value: '${status.socTempC}°C',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChipTile(
                  icon: Icons.router_outlined,
                  label: 'Latency',
                  value: '${status.tailscaleLatencyMs}ms',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shua Governor AI Aggregator Card strictly matching Stitch layout.
class _AiAggregatorCard extends StatelessWidget {
  final GovernorStatus status;

  const _AiAggregatorCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassCard(
      borderColor: const Color(0xFF00E5FF).withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHUA GOVERNOR',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI Aggregator',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00E5FF), size: 22),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active Model', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.loadedModel ?? 'qwen2.5:1.5b',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('VRAM Allocation', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(
                      '${status.ollamaRamMb?.toStringAsFixed(0) ?? "1,840"} MB / 4,096 MB',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (status.ollamaRamMb ?? 1840) / 4096.0,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Action Buttons: Load Model, Evict, Offload
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Load Model', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => context.go('/chat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.eject_outlined, size: 14),
                  label: const Text('Evict', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.computer_rounded, size: 14),
                  label: const Text('Offload', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Supervised Microservice Item matching Stitch list tile design.
class _MicroserviceTile extends ConsumerWidget {
  final String name;
  final String title;
  final IconData icon;
  final Color accentColor;
  final GovernorStatus status;
  final VoidCallback onLaunch;

  const _MicroserviceTile({
    required this.name,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.status,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = status.modules.firstWhere(
      (m) => m.name == name,
      orElse: () => ModuleStatus(name: name, state: ModuleState.stopped),
    );
    final isRunning = module.state == ModuleState.running;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning ? const Color(0xFF2DD4BF) : Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRunning ? 'ACTIVE' : 'SIGSTOP',
                      style: TextStyle(
                        color: isRunning ? const Color(0xFF2DD4BF) : Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isRunning ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
              color: isRunning ? Colors.white54 : const Color(0xFF00E5FF),
            ),
            onPressed: () {
              if (isRunning) {
                ref.read(governorStatusProvider.notifier).sleepModule(name);
              } else {
                ref.read(governorStatusProvider.notifier).wakeModule(name);
              }
            },
            tooltip: isRunning ? 'SIGSTOP Freeze' : 'Wake Module',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white54, size: 18),
            onPressed: onLaunch,
            tooltip: 'Open Module',
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _GlassCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor ?? const Color(0xFF334155).withValues(alpha: 0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GaugeMetric extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _GaugeMetric({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ],
    );
  }
}

class _ChipTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ChipTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00E5FF)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

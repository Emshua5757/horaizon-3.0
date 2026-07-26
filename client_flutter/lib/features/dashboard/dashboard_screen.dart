import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../governor/governor_provider.dart';

/// State-of-the-art native glassmorphic Dashboard for horAIzon 3.0.
/// Translates the Google Stitch designs (`Desktop Telemetry Sidebar`, `Desktop Minimized Sidebar`, `Mobile Compact`).
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
          padding: const EdgeInsets.all(20),
          children: [
            // Top Welcome Header
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
                    Text(
                      'Personal AI Operating System — Raspberry Pi 5 Active',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
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
            const SizedBox(height: 20),

            // Top Hero Row: 2 Glassmorphic Cards (Hardware Telemetry & AI Aggregator)
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _HardwareTelemetryHeroCard(status: status)),
                  const SizedBox(width: 16),
                  Expanded(child: _AiAggregatorHeroCard(status: status)),
                ],
              )
            else ...[
              _HardwareTelemetryHeroCard(status: status),
              const SizedBox(height: 16),
              _AiAggregatorHeroCard(status: status),
            ],

            const SizedBox(height: 28),

            // Microservices Management Section Header
            Row(
              children: [
                const Icon(Icons.apps_rounded, color: Color(0xFF00E5FF), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Supervised Microservices (cgroups v2 Power Control)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grid of Microservices Launcher Cards
            GridView.count(
              crossAxisCount: isDesktop ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.4 : 2.2,
              children: [
                _ModuleCard(
                  name: 'shua_diary',
                  title: 'Personal Diary & Media Vault',
                  icon: Icons.book_outlined,
                  accentColor: const Color(0xFF2DD4BF),
                  status: status,
                  description: '142 MB RAM | 384 Entries | Media Vault Active',
                  onLaunch: () => context.go('/diary'),
                ),
                _ModuleCard(
                  name: 'shua_code_viz',
                  title: 'Codebase Visualizer & AST Topology',
                  icon: Icons.account_tree_outlined,
                  accentColor: const Color(0xFF6366F1),
                  status: status,
                  description: 'AST Tree-sitter Watcher Idle',
                  onLaunch: () => context.go('/code/topology'),
                ),
                _ModuleCard(
                  name: 'shua_resume',
                  title: 'Resume Matrix & Typst Compiler',
                  icon: Icons.description_outlined,
                  accentColor: const Color(0xFFF59E0B),
                  status: status,
                  description: '88 MB RAM | 4 PDF Exhibits Compiled',
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

/// Hero Card 1: Raspberry Pi 5 Hardware Telemetry & Disaster Recovery Status.
class _HardwareTelemetryHeroCard extends StatelessWidget {
  final GovernorStatus status;

  const _HardwareTelemetryHeroCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ramPct = (status.totalRamMb / status.ramCeilingMb).clamp(0.0, 1.0);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory_rounded, color: Color(0xFF00E5FF), size: 22),
              const SizedBox(width: 8),
              Text(
                'Raspberry Pi 5 System Telemetry',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'HEALTHY',
                      style: TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hardware Gauges
          Row(
            children: [
              Expanded(
                child: _GaugeTile(
                  label: 'ARM CPU (4-Core)',
                  value: '${status.cpuUsagePct.toStringAsFixed(0)}%',
                  progress: status.cpuUsagePct / 100.0,
                  color: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GaugeTile(
                  label: 'RAM (7.1 GB Ceiling)',
                  value: '${(status.totalRamMb / 1024.0).toStringAsFixed(1)} / 7.1 GB',
                  progress: ramPct,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricChip(icon: Icons.thermostat_rounded, label: 'SoC Temp', value: '${status.socTempC}°C'),
              const SizedBox(width: 12),
              _MetricChip(icon: Icons.wifi_rounded, label: 'Tailscale RTT', value: '${status.tailscaleLatencyMs}ms'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),
          // ADR-002 Backup Badge
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF2DD4BF), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ADR-002 Backup: ${status.lastBackupTime}',
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hero Card 2: Shua Governor AI Aggregator & Active Ollama Model.
class _AiAggregatorHeroCard extends StatelessWidget {
  final GovernorStatus status;

  const _AiAggregatorHeroCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00E5FF), size: 22),
              const SizedBox(width: 8),
              Text(
                'Shua Governor AI Aggregator',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'ROUTER ACTIVE',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Model Details Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE MODEL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.loadedModel ?? 'qwen2.5:1.5b (RPi5 Edge)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Ollama Allocation: ${status.ollamaRamMb?.toStringAsFixed(0) ?? "1840"} MB',
                      style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Quick Model Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Switch Offload Engine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF00E5FF),
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => context.go('/chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Glassmorphic Microservice Card with cgroups v2 Power Toggle Switch.
class _ModuleCard extends ConsumerWidget {
  final String name;
  final String title;
  final IconData icon;
  final Color accentColor;
  final GovernorStatus status;
  final String description;
  final VoidCallback onLaunch;

  const _ModuleCard({
    required this.name,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.status,
    required this.description,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final module = status.modules.firstWhere(
      (m) => m.name == name,
      orElse: () => ModuleStatus(name: name, state: ModuleState.stopped),
    );
    final isRunning = module.state == ModuleState.running;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // cgroups v2 Power Switch (ON/Running vs OFF/Sleeping)
              Switch(
                value: isRunning,
                activeThumbColor: accentColor,
                activeTrackColor: accentColor.withValues(alpha: 0.2),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.white10,
                onChanged: (val) {
                  if (val) {
                    ref.read(governorStatusProvider.notifier).wakeModule(name);
                  } else {
                    ref.read(governorStatusProvider.notifier).sleepModule(name);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Power Status Pill
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRunning ? accentColor : Colors.amber,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isRunning ? 'ON (Running)' : 'OFF (Sleeping - SIGSTOP Frozen)',
                style: TextStyle(
                  color: isRunning ? accentColor : Colors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onLaunch,
              child: Text(isRunning ? 'Open Module' : 'Wake & Open'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Glassmorphic Card Container Widget.
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

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
            border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GaugeTile extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _GaugeTile({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF00E5FF)),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../governor/governor_provider.dart';

/// Desktop & Mobile Dashboard strictly matching Google Stitch Screenshot 2.
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
          padding: const EdgeInsets.all(24),
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
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: Color(0xFF2DD4BF), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Uptime: 14d 06h 22m',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
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
            const SizedBox(height: 24),

            // Top Hero Cards (RPI5 Edge Node Telemetry + AI Aggregator)
            if (isDesktop)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 4, child: _HardwareTelemetryHero(status: status)),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: _AiAggregatorHero(status: status)),
                  ],
                ),
              )
            else ...[
              _HardwareTelemetryHero(status: status),
              const SizedBox(height: 16),
              _AiAggregatorHero(status: status),
            ],

            const SizedBox(height: 32),

            // Supervised Microservices Header
            Row(
              children: [
                const Text(
                  'Supervised Microservices',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(cgroups v2 Power Control)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Microservices Grid / Column
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: _MicroserviceCard(
                      name: 'shua_diary',
                      title: 'shua_diary',
                      icon: Icons.book_outlined,
                      accentColor: const Color(0xFF2DD4BF),
                      status: status,
                      ramText: '142 MB RAM',
                      subText: '384 Entries',
                      buttonLabel: 'Launch Diary',
                      onLaunch: () => context.go('/diary'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MicroserviceCard(
                      name: 'shua_code_viz',
                      title: 'shua_code_viz',
                      icon: Icons.code_rounded,
                      accentColor: const Color(0xFFF59E0B),
                      status: status,
                      ramText: '0 MB RAM (Frozen)',
                      subText: '-',
                      buttonLabel: '▷ Wake & Launch',
                      onLaunch: () => context.go('/code/topology'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MicroserviceCard(
                      name: 'shua_resume',
                      title: 'shua_resume',
                      icon: Icons.description_outlined,
                      accentColor: const Color(0xFF2DD4BF),
                      status: status,
                      ramText: '88 MB RAM',
                      subText: '4 Exhibits',
                      buttonLabel: 'Launch Builder',
                      onLaunch: () => context.go('/resume/editor'),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _MicroserviceCard(
                    name: 'shua_diary',
                    title: 'shua_diary',
                    icon: Icons.book_outlined,
                    accentColor: const Color(0xFF2DD4BF),
                    status: status,
                    ramText: '142 MB RAM',
                    subText: '384 Entries',
                    buttonLabel: 'Launch Diary',
                    onLaunch: () => context.go('/diary'),
                  ),
                  const SizedBox(height: 12),
                  _MicroserviceCard(
                    name: 'shua_code_viz',
                    title: 'shua_code_viz',
                    icon: Icons.code_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    status: status,
                    ramText: '0 MB RAM (Frozen)',
                    subText: '-',
                    buttonLabel: '▷ Wake & Launch',
                    onLaunch: () => context.go('/code/topology'),
                  ),
                  const SizedBox(height: 12),
                  _MicroserviceCard(
                    name: 'shua_resume',
                    title: 'shua_resume',
                    icon: Icons.description_outlined,
                    accentColor: const Color(0xFF2DD4BF),
                    status: status,
                    ramText: '88 MB RAM',
                    subText: '4 Exhibits',
                    buttonLabel: 'Launch Builder',
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

/// Hardware Telemetry Card matching Stitch Screenshot 2.
class _HardwareTelemetryHero extends StatelessWidget {
  final GovernorStatus status;

  const _HardwareTelemetryHero({required this.status});

  @override
  Widget build(BuildContext context) {
    return _StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RPI5 EDGE NODE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Hardware Telemetry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // CPU Load Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CPU Load', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Icon(Icons.trending_up_rounded, color: Color(0xFF2DD4BF), size: 16),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${status.cpuUsagePct.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: status.cpuUsagePct / 100.0,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                  minHeight: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SoC Temp Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SoC Temp', style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '${status.socTempC.toStringAsFixed(1)}°C',
                  style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),

          // Backup Sync Footer Badge
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
              Expanded(
                child: Text(
                  'Last Backup: ${status.lastBackupTime}',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
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

/// Shua Governor AI Aggregator Hero matching Stitch Screenshot 2.
class _AiAggregatorHero extends StatelessWidget {
  final GovernorStatus status;

  const _AiAggregatorHero({required this.status});

  @override
  Widget build(BuildContext context) {
    return _StitchCard(
      borderColor: const Color(0xFF00E5FF).withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHUA GOVERNOR',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'AI Aggregator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF2DD4BF)),
                    SizedBox(width: 6),
                    Text(
                      'Router Active',
                      style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Model Info Table Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 100,
                      child: Text('Active Model', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          status.loadedModel ?? 'qwen2.5:1.5b (RPi5 Edge)',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ollama VRAM Allocation', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(
                      '${status.ollamaRamMb?.toStringAsFixed(0) ?? "1,840"} MB',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (status.ollamaRamMb ?? 1840) / 4096.0,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),

          // Action Buttons: Load Model, Evict, Switch to Laptop Offload
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00E5FF),
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => context.go('/chat'),
                  child: const Text('Load Model', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {},
                child: const Text('Evict', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.laptop_mac_rounded, size: 14, color: Color(0xFF00E5FF)),
                label: const Text('Switch to Laptop Offload', style: TextStyle(color: Colors.white70, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Microservice Card strictly matching Stitch Screenshot 2.
class _MicroserviceCard extends ConsumerWidget {
  final String name;
  final String title;
  final IconData icon;
  final Color accentColor;
  final GovernorStatus status;
  final String ramText;
  final String subText;
  final String buttonLabel;
  final VoidCallback onLaunch;

  const _MicroserviceCard({
    required this.name,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.status,
    required this.ramText,
    required this.subText,
    required this.buttonLabel,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = status.modules.firstWhere(
      (m) => m.name == name,
      orElse: () => ModuleStatus(name: name, state: ModuleState.stopped),
    );
    final isRunning = module.state == ModuleState.running;

    return _StitchCard(
      borderColor: isRunning ? const Color(0xFF2DD4BF).withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRunning ? const Color(0xFF2DD4BF) : Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ramText, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(subText, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isRunning ? Colors.white : Colors.amber,
                side: BorderSide(color: isRunning ? Colors.white24 : Colors.amber.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                if (!isRunning) {
                  ref.read(governorStatusProvider.notifier).wakeModule(name);
                }
                onLaunch();
              },
              child: Text(buttonLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StitchCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _StitchCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? Colors.white10, width: 1),
      ),
      child: child,
    );
  }
}

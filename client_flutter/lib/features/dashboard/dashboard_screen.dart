import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../governor/governor_provider.dart';
import 'widgets/ai_aggregator_hero.dart';
import 'widgets/dashboard_welcome_header.dart';
import 'widgets/hardware_telemetry_hero.dart';
import 'widgets/microservices_section.dart';

/// Refactored, modularized Desktop & Mobile Dashboard strictly matching Google Stitch specifications.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(governorStatusProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: statusAsync.when(
        data: (status) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              children: [
                // Welcome Header
                const DashboardWelcomeHeader(),
                const SizedBox(height: 24),

                // Top Hero Section (Symmetrical 1:1 ratio for Hardware Telemetry + AI Aggregator)
                if (isDesktop)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: HardwareTelemetryHero(status: status)),
                        const SizedBox(width: 20),
                        Expanded(child: AiAggregatorHero(status: status)),
                      ],
                    ),
                  )
                else ...[
                  HardwareTelemetryHero(status: status),
                  const SizedBox(height: 16),
                  AiAggregatorHero(status: status),
                ],

                const SizedBox(height: 32),

                // Supervised Microservices Grid
                MicroservicesSection(status: status, isDesktop: isDesktop),
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading status: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

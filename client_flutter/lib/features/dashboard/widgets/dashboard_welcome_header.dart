import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../governor/governor_provider.dart';

/// Refined Obsidian Horizon Welcome Header strictly matching Stitch specifications.
class DashboardWelcomeHeader extends ConsumerWidget {
  const DashboardWelcomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Joshua',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFD4E4FA),
                fontWeight: FontWeight.w700,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF3CE36A),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  'Uptime: 14d 06h 22m',
                  style: TextStyle(
                    color: const Color(0xFFC8C5CB).withValues(alpha: 0.8),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        // Sleek Telemetry Refresh Pill Button
        InkWell(
          onTap: () => ref.read(governorStatusProvider.notifier).refresh(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF), size: 16),
                SizedBox(width: 8),
                Text(
                  'Refresh',
                  style: TextStyle(
                    color: Color(0xFFD4E4FA),
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

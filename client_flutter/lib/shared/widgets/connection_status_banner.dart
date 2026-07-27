import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/hbp/hbp_client.dart';
import '../../core/hbp/hbp_client_provider.dart';

/// Animated top banner displaying live WebSocket connection health to Raspberry Pi 5.
class ConnectionStatusBanner extends ConsumerWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(hbpConnectionStateProvider);
    final theme = Theme.of(context);

    return stateAsync.when(
      data: (state) {
        if (state == HbpConnectionState.connected) return const SizedBox.shrink();

        final (color, message) = switch (state) {
          HbpConnectionState.connecting => (Colors.amber.shade700, 'Connecting to Pi 5 (ws://100.67.11.0:7700)…'),
          HbpConnectionState.reconnecting => (Colors.amber.shade800, 'Reconnecting to Pi 5…'),
          _ => (Colors.red.shade800, 'Offline — Disconnected from Pi 5 (ws://100.67.11.0:7700)'),
        };

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          color: color.withValues(alpha: 0.92),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state == HbpConnectionState.connecting || state == HbpConnectionState.reconnecting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/hbp/hbp_client_provider.dart';
import '../core/hbp/hbp_client.dart';

/// Splash screen displayed on app launch.
/// Attempts to connect to the shua_governor HBP v2 WebSocket.
/// On success → routes to /dashboard. On failure → shows retry UI.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  String _statusText = 'Connecting to Pi 5…';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _attemptConnect();
  }

  Future<void> _attemptConnect() async {
    setState(() {
      _statusText = 'Connecting to Pi 5…';
      _failed = false;
    });

    try {
      // Watch the hbpClientProvider to trigger connection
      final client = await ref.read(hbpClientProvider.future).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Governor not reachable'),
      );

      if (!mounted) return;

      if (client.currentState == HbpConnectionState.connected) {
        setState(() => _statusText = 'Connected ✓');
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/dashboard');
      } else {
        _setFailed();
      }
    } catch (_) {
      if (mounted) _setFailed();
    }
  }

  void _setFailed() {
    setState(() {
      _statusText = 'Could not reach Governor';
      _failed = true;
    });
  }

  @override
  void dispose() {
    _pulseCtrl.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated logo emblem
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Opacity(
                opacity: _pulse.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.6),
                        cs.surface,
                      ],
                    ),
                    border: Border.all(color: cs.primary, width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      'hAI',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'horAIzon 3.0',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: TextStyle(
                color: _failed ? cs.error : cs.primary,
                fontSize: 14,
              ),
            ),
            if (!_failed) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  color: cs.primary,
                  backgroundColor: cs.primary.withValues(alpha: 0.2),
                ),
              ),
            ],
            if (_failed) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // Invalidate provider to re-trigger connection
                  ref.invalidate(hbpClientProvider);
                  _attemptConnect();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Continue Offline'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

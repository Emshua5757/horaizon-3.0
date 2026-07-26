import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/hbp/hbp_client_provider.dart';
import '../core/hbp/hbp_client.dart';

/// Premium cybernetic splash screen for horAIzon 3.0.
/// Pings shua_governor HBP v2 WebSocket on launch.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  String _statusText = 'Establishing HBP v2 Connection…';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _attemptConnect();
  }

  Future<void> _attemptConnect() async {
    setState(() {
      _statusText = 'Connecting to Governor port 7700…';
      _failed = false;
    });

    try {
      final client = await ref.read(hbpClientProvider.future).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Governor connection timeout'),
      );

      if (!mounted) return;

      if (client.currentState == HbpConnectionState.connected) {
        setState(() => _statusText = 'Connected to Pi 5 ✓');
        await Future.delayed(const Duration(milliseconds: 500));
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
      _statusText = 'Governor unreachable on LAN/Tailscale';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Cyber Emblem Logo
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            cs.primary.withValues(alpha: 0.35),
                            cs.surface,
                          ],
                        ),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.8),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.4),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'h3',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // App Title
                Text(
                  'horAIzon 3.0',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-Native Autonomous Workspace',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 36),
                // Status Badge Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: (_failed ? cs.error : cs.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (_failed ? cs.error : cs.primary).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: _failed
                            ? Icon(Icons.error_outline, size: 12, color: cs.error)
                            : CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _statusText,
                        style: TextStyle(
                          color: _failed ? cs.error : cs.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_failed) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(hbpClientProvider);
                          _attemptConnect();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Connection'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => context.go('/dashboard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          side: BorderSide(color: cs.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Continue Offline'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

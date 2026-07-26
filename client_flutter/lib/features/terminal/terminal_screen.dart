import 'package:flutter/material.dart';

/// Embedded Multi-Tab Terminal Screen for horAIzon 3.0.
class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Terminal Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.65),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.terminal_rounded, color: Color(0xFF00E5FF), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Session 1: RPi5 SSH (100.67.11.0:7700)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Terminal Console Body
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                ),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'root@horaizon-pi5:~# systemctl status shua_governor',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '● shua_governor.service - horAIzon 3.0 Governor Daemon\n'
                        '   Loaded: loaded (/etc/systemd/system/shua_governor.service; enabled)\n'
                        '   Active: active (running) since Sun 2026-07-26 13:00:00 PHT\n'
                        '   Memory: 142.4M (ceiling: 7168.0M)\n'
                        '   CGroup: /horaizon.slice/shua_governor.service\n'
                        '           └─7700 /opt/horaizon/bin/shua_governor\n\n'
                        '[INFO shua_governor::broker] HBP v2 WebSocket listening on 100.67.11.0:7700\n'
                        '[INFO shua_governor::cgroups] Registered sub-modules: shua_diary, shua_code_viz, shua_resume\n'
                        '[INFO shua_governor::dream_loop] Next Dream Loop snapshot: 03:00:00 Asia/Manila',
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'root@horaizon-pi5:~# _',
                        style: TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

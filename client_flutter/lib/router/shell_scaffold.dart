import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/hbp/hbp_client_provider.dart';
import '../core/hbp/hbp_client.dart';

/// State-of-the-art responsive navigation shell for horAIzon 3.0.
/// Enforces clean global system destinations (Dashboard, Global Chat, Terminal, Settings).
/// Sub-modules (Diary, Resume, Code Visualizer) are launched from the Dashboard launchpad.
class ShellScaffold extends ConsumerWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  static const _destinations = [
    _Dest(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
      path: '/dashboard',
    ),
    _Dest(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome_rounded,
      label: 'AI Chat',
      path: '/chat',
    ),
    _Dest(
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal_rounded,
      label: 'Terminal',
      path: '/governor/logs',
    ),
    _Dest(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
      path: '/settings',
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);
    final isWide = MediaQuery.of(context).size.width >= 640;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final connState = ref.watch(hbpConnectionStateProvider).valueOrNull ?? HbpConnectionState.disconnected;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            // Premium Glassmorphic Side Navigation Panel
            Container(
              width: 104,
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  right: BorderSide(
                    color: cs.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // App Brand Logo Emblem
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          cs.primary,
                          cs.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'h3',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'horAIzon',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  const SizedBox(height: 16),
                  // Navigation Items
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _destinations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final d = _destinations[i];
                        final isSelected = selectedIndex == i;
                        return _NavTile(
                          destination: d,
                          isSelected: isSelected,
                          onTap: () => context.go(d.path),
                        );
                      },
                    ),
                  ),
                  // Connection Status Pill Footer
                  _ConnectionFooter(connState: connState),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Main Screen Body
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile / Narrow Glassmorphic Bottom Navigation Bar
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.92),
          border: Border(
            top: BorderSide(
              color: cs.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => context.go(_destinations[i].path),
          backgroundColor: Colors.transparent,
          indicatorColor: cs.primaryContainer,
          elevation: 0,
          destinations: _destinations
              .map((d) => NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon, color: cs.primary),
                    label: d.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _Dest destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Tooltip(
      message: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? cs.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            border: isSelected
                ? Border.all(color: cs.primary.withValues(alpha: 0.4), width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                destination.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionFooter extends StatelessWidget {
  final HbpConnectionState connState;

  const _ConnectionFooter({required this.connState});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, label) = switch (connState) {
      HbpConnectionState.connected    => (const Color(0xFF00E5A0), 'ONLINE'),
      HbpConnectionState.connecting   => (Colors.amber, 'CONNECTING'),
      HbpConnectionState.reconnecting => (Colors.orange, 'RETRYING'),
      HbpConnectionState.disconnected => (cs.error, 'OFFLINE'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dest {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;

  const _Dest({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/hbp/hbp_client_provider.dart';
import '../core/hbp/hbp_client.dart';
import '../features/governor/governor_provider.dart';

/// StateProvider for expanding/minimizing the desktop navigation sidebar.
final isSidebarExpandedProvider = StateProvider<bool>((ref) => true);

/// Responsive navigation shell strictly translating Google Stitch desktop and mobile designs.
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
      label: 'JOSH',
      path: '/chat',
    ),
    _Dest(
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal_rounded,
      label: 'Terminal',
      path: '/terminal',
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
    final mediaWidth = MediaQuery.of(context).size.width;
    final isMobile = mediaWidth < 640;
    final isExpanded = ref.watch(isSidebarExpandedProvider) && mediaWidth >= 900;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final connState = ref.watch(hbpConnectionStateProvider).valueOrNull ?? HbpConnectionState.disconnected;

    if (!isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: Row(
          children: [
            // Glassmorphic Desktop Side Navigation Sidebar (Expanded vs Minimized Rail)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isExpanded ? 260 : 80,
              decoration: BoxDecoration(
                color: const Color(0xFF090D16),
                border: Border(
                  right: BorderSide(
                    color: cs.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _SidebarHeader(
                    isExpanded: isExpanded,
                    connState: connState,
                  ),
                  const SizedBox(height: 16),
                  const Divider(indent: 16, endIndent: 16, height: 1, color: Colors.white12),
                  const SizedBox(height: 16),

                  // 4 Primary Global Navigation Destinations
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _destinations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final d = _destinations[i];
                        final isSelected = selectedIndex == i;
                        return _NavTile(
                          destination: d,
                          isSelected: isSelected,
                          isExpanded: isExpanded,
                          onTap: () => context.go(d.path),
                        );
                      },
                    ),
                  ),

                  // Sidebar Collapse/Expand Toggle Button at Bottom
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.arrow_back_ios_new_rounded
                          : Icons.arrow_forward_ios_rounded,
                      color: cs.onSurface.withValues(alpha: 0.5),
                      size: 18,
                    ),
                    onPressed: () {
                      ref.read(isSidebarExpandedProvider.notifier).state = !isExpanded;
                    },
                    tooltip: isExpanded ? 'Minimize Sidebar' : 'Expand Sidebar',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Main Screen Canvas with Top Navigation History Header
            Expanded(
              child: Column(
                children: [
                  _DesktopHeader(
                    title: _destinations[selectedIndex].label,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout strictly matching Google Stitch `Mobile | Dashboard - Compact`
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Column(
          children: [
            // Stitch Mobile Header (Logo + Bell + Avatar)
            const _MobileHeader(),
            Expanded(child: child),
          ],
        ),
      ),
      // Floating Status Bar + Compact Bottom Navigation Bar
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stitch Mobile Floating RPi5 Connection Pill
          _MobileFloatingPill(connState: connState),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF090D16),
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
              indicatorColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              elevation: 0,
              destinations: _destinations
                  .map((d) => NavigationDestination(
                        icon: Icon(d.icon, color: Colors.white54),
                        selectedIcon: Icon(d.selectedIcon, color: const Color(0xFF00E5FF)),
                        label: d.label,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Google Stitch Mobile Header (horAIzon 3.0 + Bell Icon + User Profile Avatar)
class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF090D16),
        border: Border(
          bottom: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'horAIzon 3.0',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'AI OPERATING SYSTEM',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF00E5FF), size: 22),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2DD4BF), width: 1.5),
            ),
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.person_rounded, size: 16, color: Color(0xFF00E5FF)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stitch Mobile Floating Connection Pill (`((•)) RPi5: 5MS | ONLINE`)
class _MobileFloatingPill extends ConsumerWidget {
  final HbpConnectionState connState;

  const _MobileFloatingPill({required this.connState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(governorStatusProvider).valueOrNull;
    final (color, label) = switch (connState) {
      HbpConnectionState.connected    => (const Color(0xFF2DD4BF), 'RPi5: ${status?.tailscaleLatencyMs ?? 5}MS | ONLINE'),
      HbpConnectionState.connecting   => (Colors.amber, 'RPi5: CONNECTING...'),
      HbpConnectionState.reconnecting => (Colors.orange, 'RPi5: RETRYING...'),
      HbpConnectionState.disconnected => (const Color(0xFFEF4444), 'RPi5: OFFLINE'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop Navigation Header with Back (`<`) and Forward (`>`) route buttons.
class _DesktopHeader extends StatelessWidget {
  final String title;

  const _DesktopHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final canPop = context.canPop();

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        border: Border(
          bottom: BorderSide(
            color: cs.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: canPop ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
              size: 26,
            ),
            onPressed: canPop ? () => context.pop() : null,
            tooltip: 'Go Back',
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.3),
              size: 26,
            ),
            onPressed: null,
            tooltip: 'Go Forward',
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            'System Uptime: 14d 06h 22m',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop Sidebar Header displaying Profile Avatar & RPi5 LED Connection Status.
class _SidebarHeader extends StatelessWidget {
  final bool isExpanded;
  final HbpConnectionState connState;

  const _SidebarHeader({
    required this.isExpanded,
    required this.connState,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (statusColor, statusText) = switch (connState) {
      HbpConnectionState.connected    => (const Color(0xFF2DD4BF), 'RPi5 Connected'),
      HbpConnectionState.connecting   => (Colors.amber, 'Connecting...'),
      HbpConnectionState.reconnecting => (Colors.orange, 'Retrying...'),
      HbpConnectionState.disconnected => (const Color(0xFFEF4444), 'RPi5 Disconnected'),
    };

    if (!isExpanded) {
      return Tooltip(
        message: 'Joshua B. Ygot ($statusText)',
        child: CircleAvatar(
          radius: 20,
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.person_rounded, size: 18, color: cs.primary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withValues(alpha: 0.2),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.person_rounded, size: 18, color: cs.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Joshua B. Ygot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(color: statusColor, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _Dest destination;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavTile({
    required this.destination,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const activeColor = Color(0xFF00E5FF);

    return Tooltip(
      message: isExpanded ? '' : destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 16 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            border: isSelected
                ? Border.all(color: activeColor.withValues(alpha: 0.4), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment:
                isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                color: isSelected ? activeColor : cs.onSurface.withValues(alpha: 0.6),
                size: 22,
              ),
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? activeColor : cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
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

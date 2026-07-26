import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/hbp/hbp_client_provider.dart';
import '../core/hbp/hbp_client.dart';

/// StateProvider for expanding/minimizing the desktop navigation sidebar.
final isSidebarExpandedProvider = StateProvider<bool>((ref) => true);

/// State-of-the-art responsive navigation shell for horAIzon 3.0.
/// Implements 3 responsive modes strictly aligned with Stitch designs:
/// 1. Desktop Expanded (260px width) — `Desktop | Dashboard - Telemetry Sidebar`
/// 2. Desktop Minimized (80px width) — `Desktop | Dashboard - Minimized Sidebar`
/// 3. Mobile Compact — `Mobile | Dashboard - Compact`
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
                  // Header: Profile & Status Indicator
                  _SidebarHeader(
                    isExpanded: isExpanded,
                    connState: connState,
                  ),
                  const SizedBox(height: 16),
                  const Divider(indent: 16, endIndent: 16, height: 1),
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

            // Main Screen Canvas with Top History Navigation Header (< and >)
            Expanded(
              child: Column(
                children: [
                  // Global Top Navigation History Bar
                  _TopHistoryHeader(
                    title: _destinations[selectedIndex].label,
                  ),
                  // Active Screen Child
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Compact Bottom Navigation Shell (`Mobile | Dashboard - Compact`)
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopHistoryHeader(title: _destinations[selectedIndex].label),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
          indicatorColor: cs.primary.withValues(alpha: 0.2),
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

/// Top Navigation Header incorporating Route History Back (`<`) and Forward (`>`) controls.
class _TopHistoryHeader extends StatelessWidget {
  final String title;

  const _TopHistoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final canPop = context.canPop();

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF090D16).withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: cs.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button (<)
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: canPop ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
              size: 26,
            ),
            onPressed: canPop ? () => context.pop() : null,
            tooltip: 'Go Back',
          ),
          const SizedBox(width: 4),
          // Forward Button (>)
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.3),
              size: 26,
            ),
            onPressed: null, // GoRouter pop-forward stack placeholder
            tooltip: 'Go Forward',
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // System Uptime Indicator
          Text(
            'Uptime: 14d 06h 22m',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar Header displaying Profile Avatar & RPi5 LED Connection Status.
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

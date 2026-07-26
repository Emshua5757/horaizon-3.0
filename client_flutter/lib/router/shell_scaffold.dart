import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/hbp/hbp_client_provider.dart';
import '../core/hbp/hbp_client.dart';
import '../features/governor/governor_provider.dart';

/// StateProvider for expanding/minimizing the desktop navigation sidebar.
final isSidebarExpandedProvider = StateProvider<bool>((ref) => false);

/// Responsive navigation shell strictly translating Google Stitch desktop & mobile designs.
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
              width: isExpanded ? 240 : 72,
              decoration: BoxDecoration(
                color: const Color(0xFF070A10),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Top Profile Avatar Emblem
                  _SidebarProfile(isExpanded: isExpanded, connState: connState),
                  const SizedBox(height: 20),

                  // 4 Primary Global Navigation Destinations
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _destinations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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

                  // Sidebar Telemetry Readouts at Bottom (Stitch Desktop Design)
                  _SidebarTelemetry(isExpanded: isExpanded),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Main Screen Canvas with Stitch Top Header
            Expanded(
              child: Column(
                children: [
                  _DesktopHeader(title: _destinations[selectedIndex].label),
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
            const _MobileHeader(),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

/// Sidebar Telemetry Readouts at bottom of Rail strictly matching Stitch Screenshot 2.
class _SidebarTelemetry extends ConsumerWidget {
  final bool isExpanded;

  const _SidebarTelemetry({required this.isExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(governorStatusProvider).valueOrNull;
    final cpu = status?.cpuUsagePct.toStringAsFixed(0) ?? '18';
    final mem = ((status?.totalRamMb ?? 2140) / 1024).toStringAsFixed(1);
    final temp = status?.socTempC.toStringAsFixed(0) ?? '42';
    final ping = status?.tailscaleLatencyMs ?? 12;

    if (isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            _TelemetryLine(label: 'CPU', value: '$cpu%'),
            _TelemetryLine(label: 'MEM', value: '${mem}G', color: const Color(0xFF00E5FF)),
            _TelemetryLine(label: 'TMP', value: '$temp°', color: const Color(0xFF2DD4BF)),
            _TelemetryLine(label: 'PNG', value: '${ping}ms', color: const Color(0xFF00E5FF)),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Divider(indent: 12, endIndent: 12, color: Colors.white10),
        const SizedBox(height: 6),
        _TelemetryMiniBlock(label: 'CPU', value: '$cpu%'),
        const SizedBox(height: 6),
        _TelemetryMiniBlock(label: 'MEM', value: '${mem}G', color: const Color(0xFF00E5FF)),
        const SizedBox(height: 6),
        _TelemetryMiniBlock(label: 'TMP', value: '$temp°', color: const Color(0xFF2DD4BF)),
        const SizedBox(height: 6),
        _TelemetryMiniBlock(label: 'PNG', value: '${ping}ms', color: const Color(0xFF00E5FF)),
      ],
    );
  }
}

class _TelemetryMiniBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _TelemetryMiniBlock({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: TextStyle(color: color ?? Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _TelemetryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _TelemetryLine({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Desktop Header matching Stitch Screenshot 2 (`Workspace > Dashboard` + Search + Bell + Connect Node).
class _DesktopHeader extends StatelessWidget {
  final String title;

  const _DesktopHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF090D16),
        border: Border(
          bottom: BorderSide(
            color: Colors.white10,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb Title (`Workspace > Dashboard`)
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Workspace  ›  ',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
                TextSpan(
                  text: title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Action Buttons: Search, Bell, Connect Node
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
            onPressed: () {},
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 20),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.hub_outlined, size: 14, color: Color(0xFF00E5FF)),
            label: const Text('Connect Node', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00E5FF)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

/// Sidebar Profile Emblem matching Stitch Screenshot 2.
class _SidebarProfile extends StatelessWidget {
  final bool isExpanded;
  final HbpConnectionState connState;

  const _SidebarProfile({
    required this.isExpanded,
    required this.connState,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusText) = switch (connState) {
      HbpConnectionState.connected    => (const Color(0xFF2DD4BF), 'RPi5 Connected'),
      HbpConnectionState.connecting   => (Colors.amber, 'Connecting...'),
      HbpConnectionState.reconnecting => (Colors.orange, 'Retrying...'),
      HbpConnectionState.disconnected => (const Color(0xFFEF4444), 'RPi5 Disconnected'),
    };

    if (!isExpanded) {
      return Tooltip(
        message: 'Joshua B. Ygot ($statusText)',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E293B),
            border: Border.all(color: statusColor, width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, size: 20, color: Color(0xFF00E5FF)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E293B),
              border: Border.all(color: statusColor, width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, size: 20, color: Color(0xFF00E5FF)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Joshua B. Ygot',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF090D16),
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'horAIzon 3.0',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              Text(
                'AI OPERATING SYSTEM',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1),
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
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
    const activeColor = Color(0xFF00E5FF);

    return Tooltip(
      message: isExpanded ? '' : destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 14 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
            border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.4), width: 1) : null,
          ),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                color: isSelected ? activeColor : Colors.white54,
                size: 22,
              ),
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? activeColor : Colors.white70,
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

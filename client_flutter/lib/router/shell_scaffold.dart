import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/hbp/hbp_client_provider.dart';
import '../core/hbp/hbp_client.dart';
import '../features/governor/governor_provider.dart';

/// StateProvider for expanding/minimizing the desktop navigation sidebar.
final isSidebarExpandedProvider = StateProvider<bool>((ref) => true);

/// Responsive navigation shell strictly matching Google Stitch 'Desktop | Dashboard - Telemetry Sidebar'.
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
      icon: Icons.psychology_outlined,
      selectedIcon: Icons.psychology_rounded,
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
        backgroundColor: const Color(0xFF050508),
        body: Row(
          children: [
            // Glassmorphic Obsidian Sidebar matching Stitch
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isExpanded ? 260 : 72,
              decoration: BoxDecoration(
                color: const Color(0xFF051424).withValues(alpha: 0.95),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Brand Header matching Stitch
                  _SidebarBrandHeader(isExpanded: isExpanded),
                  const SizedBox(height: 24),

                  // Primary Navigation Items
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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

                  // Bottom System Telemetry Card matching Stitch
                  _SidebarTelemetryCard(isExpanded: isExpanded),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Main Screen Canvas with Top App Header
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

    // Mobile Navigation Shell
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
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
              color: const Color(0xFF050508),
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

/// Brand Header matching Google Stitch (`dataset` emblem + title).
class _SidebarBrandHeader extends ConsumerWidget {
  final bool isExpanded;

  const _SidebarBrandHeader({required this.isExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isExpanded) {
      return IconButton(
        icon: const Icon(Icons.dataset_rounded, color: Color(0xFF00E5FF), size: 24),
        onPressed: () => ref.read(isSidebarExpandedProvider.notifier).state = true,
        tooltip: 'Expand Sidebar',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.dataset_rounded, color: Color(0xFF00E5FF), size: 24),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'horAIzon 3.0',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54, size: 20),
            onPressed: () => ref.read(isSidebarExpandedProvider.notifier).state = false,
            tooltip: 'Collapse Sidebar',
          ),
        ],
      ),
    );
  }
}

/// System Telemetry Footer Block matching Stitch.
class _SidebarTelemetryCard extends ConsumerWidget {
  final bool isExpanded;

  const _SidebarTelemetryCard({required this.isExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(governorStatusProvider).valueOrNull;
    final cpuPct = status?.cpuUsagePct ?? 18.0;
    final cpuStr = cpuPct.toStringAsFixed(0);
    final usedRamGb = ((status?.totalRamMb ?? 2140.0) / 1024.0).toStringAsFixed(1);
    final totalRamGb = ((status?.ramCeilingMb ?? 7168.0) / 1024.0).toStringAsFixed(1);
    final tempStr = (status?.socTempC ?? 41.8).toStringAsFixed(1);
    final pingMs = status?.tailscaleLatencyMs ?? 12;

    if (!isExpanded) {
      return Column(
        children: [
          Divider(indent: 12, endIndent: 12, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 4),
          _MiniTelemetryTag(label: 'CPU', value: '$cpuStr%'),
          const SizedBox(height: 4),
          _MiniTelemetryTag(label: 'MEM', value: '${usedRamGb}G', color: const Color(0xFF00E5FF)),
          const SizedBox(height: 4),
          _MiniTelemetryTag(label: 'TMP', value: '$tempStr°', color: const Color(0xFF3CE36A)),
          const SizedBox(height: 4),
          _MiniTelemetryTag(label: 'PNG', value: '${pingMs}ms', color: const Color(0xFF00E5FF)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SYSTEM TELEMETRY',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Operational',
                  style: TextStyle(color: Color(0xFF3CE36A), fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // CPU Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CPU', style: TextStyle(color: Colors.white54, fontSize: 10)),
                Text('$cpuStr%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (cpuPct / 100.0).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3CE36A)),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 8),

            // MEM Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MEM', style: TextStyle(color: Colors.white54, fontSize: 10)),
                Text('$usedRamGb/${totalRamGb}GB', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ((status?.totalRamMb ?? 2140.0) / (status?.ramCeilingMb ?? 7168.0)).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 8),

            // Temp & Latency Split
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TEMP', style: TextStyle(color: Colors.white54, fontSize: 8)),
                    Text('$tempStr°C', style: const TextStyle(color: Color(0xFF3CE36A), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('PING', style: TextStyle(color: Colors.white54, fontSize: 8)),
                    Text('${pingMs}ms', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTelemetryTag extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniTelemetryTag({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Desktop Header strictly matching Google Stitch (`<-` `->` `Workspace > Dashboard` + Search + Bell).
class _DesktopHeader extends StatelessWidget {
  final String title;

  const _DesktopHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF050508).withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back & Forward navigation buttons matching Stitch screenshot
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 18),
            onPressed: () => context.canPop() ? context.pop() : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Back',
          ),
          const IconButton(
            icon: Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 18),
            onPressed: null,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Forward',
          ),
          const SizedBox(width: 8),
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
      decoration: BoxDecoration(
        color: const Color(0xFF050508),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1)),
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
              border: Border.all(color: const Color(0xFF3CE36A), width: 1.5),
            ),
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF122131),
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
      HbpConnectionState.connected    => (const Color(0xFF3CE36A), 'RPi5: ${status?.tailscaleLatencyMs ?? 12}MS | ONLINE'),
      HbpConnectionState.connecting   => (Colors.amber, 'RPi5: CONNECTING...'),
      HbpConnectionState.reconnecting => (Colors.orange, 'RPi5: RETRYING...'),
      HbpConnectionState.disconnected => (const Color(0xFFEF4444), 'RPi5: OFFLINE'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF122131).withValues(alpha: 0.9),
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

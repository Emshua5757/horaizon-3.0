import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/hbp/hbp_client_provider.dart';
import '../core/hbp/hbp_client.dart';
import '../features/governor/governor_provider.dart';
import '../shared/widgets/connection_status_banner.dart';
import '../shared/widgets/telemetry_sparkline.dart';
import '../core/theme/app_semantic_palette.dart';

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
    final isExpanded =
        ref.watch(isSidebarExpandedProvider) && mediaWidth >= 900;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final connState = ref.watch(hbpConnectionStateProvider).valueOrNull ??
        HbpConnectionState.disconnected;

    if (!isMobile) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            // Glassmorphic Sidebar matching active theme preset
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isExpanded ? 260 : 72,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow.withValues(alpha: 0.95),
                border: Border(
                  right: BorderSide(
                    color: cs.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: ClipRect(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Brand Header matching Stitch
                    _SidebarBrandHeader(isExpanded: isExpanded),
                    const SizedBox(height: 24),

                    // Primary Navigation Items
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                            horizontal: isExpanded ? 12 : 14),
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
            ),

            // Main Screen Canvas with Top App Header
            Expanded(
              child: Column(
                children: [
                  const ConnectionStatusBanner(),
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionStatusBanner(),
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
              color: cs.surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => context.go(_destinations[i].path),
              backgroundColor: Colors.transparent,
              indicatorColor: cs.primary.withValues(alpha: 0.15),
              elevation: 0,
              destinations: _destinations
                  .map((d) => NavigationDestination(
                        icon: Icon(d.icon, color: cs.onSurfaceVariant),
                        selectedIcon: Icon(d.selectedIcon, color: cs.primary),
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
    return SizedBox(
      height: 40,
      width: isExpanded ? 260 : 72,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 0),
        child: Row(
          mainAxisAlignment:
              isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.dataset_rounded,
                  color: Color(0xFF00E5FF), size: 24),
              onPressed: () {
                ref.read(isSidebarExpandedProvider.notifier).state =
                    !isExpanded;
              },
              tooltip: isExpanded ? 'Collapse Sidebar' : 'Expand Sidebar',
            ),
            if (isExpanded)
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isExpanded ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'horAIzon 3.0',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.clip,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.chevron_left_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 20),
                          onPressed: () => ref
                              .read(isSidebarExpandedProvider.notifier)
                              .state = false,
                          tooltip: 'Collapse Sidebar',
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

/// System Telemetry Footer Block with Windows Task Manager style mini sparklines.
class _SidebarTelemetryCard extends ConsumerWidget {
  final bool isExpanded;

  const _SidebarTelemetryCard({required this.isExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(governorStatusProvider).valueOrNull;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = theme.extension<AppSemanticPalette>();

    final successColor = semantic?.success ?? const Color(0xFF10B981);
    final infoColor = semantic?.info ?? const Color(0xFF00E5FF);
    const tempColor = Color(0xFFF59E0B);
    const pingColor = Color(0xFFA855F7);

    final cpuPct = status?.cpuUsagePct ?? 18.0;
    final cpuStr = cpuPct.toStringAsFixed(0);
    final usedRamGb =
        ((status?.totalRamMb ?? 2140.0) / 1024.0).toStringAsFixed(1);
    final totalRamGb =
        ((status?.ramCeilingMb ?? 7168.0) / 1024.0).toStringAsFixed(1);
    final tempStr = (status?.socTempC ?? 41.8).toStringAsFixed(1);
    final pingMs = status?.tailscaleLatencyMs ?? 12;

    final cpuHist = status?.cpuHistory ?? [12.0, 15.0, 18.0, 14.0, 16.0, 18.0];
    final ramHist =
        status?.ramHistory ?? [2100.0, 2120.0, 2140.0, 2130.0, 2140.0];
    final tempHist = status?.tempHistory ?? [40.5, 41.0, 41.5, 41.8, 41.6];
    final pingHist = status?.latencyHistory ?? [14.0, 12.0, 13.0, 12.0, 12.0];

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: SizedBox(
        width: 72,
        child: Column(
          children: [
            Divider(indent: 12, endIndent: 12, color: cs.outlineVariant),
            const SizedBox(height: 4),
            _MiniTelemetryTag(
                label: 'CPU',
                value: '$cpuStr%',
                values: cpuHist,
                color: successColor),
            const SizedBox(height: 6),
            _MiniTelemetryTag(
                label: 'MEM',
                value: '${usedRamGb}G',
                values: ramHist,
                color: infoColor),
            const SizedBox(height: 6),
            _MiniTelemetryTag(
                label: 'TMP',
                value: '$tempStr°',
                values: tempHist,
                color: tempColor),
            const SizedBox(height: 6),
            _MiniTelemetryTag(
                label: 'PNG',
                value: '${pingMs}ms',
                values: pingHist,
                color: pingColor),
          ],
        ),
      ),
      secondChild: ClipRect(
        child: SizedBox(
          width: 236,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SYSTEM TELEMETRY',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Operational',
                        style: TextStyle(
                            color: successColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // CPU Windows Task Manager Style Sparkline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CPU UTILIZATION',
                          style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                      Text('$cpuStr%',
                          style: TextStyle(
                              color: successColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  TelemetrySparkline(
                    values: cpuHist,
                    lineColor: successColor,
                    height: 24,
                    minVal: 0,
                    maxVal: 100,
                  ),
                  const SizedBox(height: 8),

                  // MEM Windows Task Manager Style Sparkline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MEMORY USAGE',
                          style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                      Text('$usedRamGb/${totalRamGb}GB',
                          style: TextStyle(
                              color: infoColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  TelemetrySparkline(
                    values: ramHist,
                    lineColor: infoColor,
                    height: 24,
                  ),
                  const SizedBox(height: 8),

                  // Bottom Grid: RPi5 Temp & Latency Sparklines
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('TEMP',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                                Text('$tempStr°C',
                                    style: const TextStyle(
                                        color: tempColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            TelemetrySparkline(
                              values: tempHist,
                              lineColor: tempColor,
                              height: 18,
                              showGrid: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('PING',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                                Text('${pingMs}ms',
                                    style: const TextStyle(
                                        color: pingColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            TelemetrySparkline(
                              values: pingHist,
                              lineColor: pingColor,
                              height: 18,
                              showGrid: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTelemetryTag extends StatelessWidget {
  final String label;
  final String value;
  final List<double>? values;
  final Color? color;

  const _MiniTelemetryTag({
    required this.label,
    required this.value,
    this.values,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = color ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
              Text(value,
                  style: TextStyle(
                      color: activeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          if (values != null && values!.isNotEmpty) ...[
            const SizedBox(height: 2),
            TelemetrySparkline(
              values: values!,
              lineColor: activeColor,
              height: 12,
              showGrid: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Desktop Header strictly matching Google Stitch (`<-` `->` `Workspace > Dashboard` + Search + Bell).
class _DesktopHeader extends StatelessWidget {
  final String title;

  const _DesktopHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back & Forward navigation buttons matching Stitch screenshot
          IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 18),
            onPressed: () => context.canPop() ? context.pop() : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Back',
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5),
                size: 18),
            onPressed: null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Forward',
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Workspace  ›  ',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13),
                ),
                TextSpan(
                  text: title,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20),
            onPressed: () {
              // TODO: Implement Global Command Palette / Search Modal (TASK-022)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Global Search / Command Palette coming soon.')),
              );
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20),
            onPressed: () {
              // TODO: Implement Central Notification & Alert Drawer (TASK-023)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notification Center coming soon.')),
              );
            },
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
    final cs = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticPalette>();
    final successColor = semantic?.success ?? cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'horAIzon 3.0',
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5),
              ),
              Text(
                'AI OPERATING SYSTEM',
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon:
                Icon(Icons.notifications_outlined, color: cs.primary, size: 22),
            onPressed: () {
              // TODO: Implement Central Notification & Alert Drawer (TASK-023)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notification Center coming soon.')),
              );
            },
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: successColor, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: cs.surface,
              child: Icon(Icons.person_rounded, size: 16, color: cs.primary),
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
    final cs = Theme.of(context).colorScheme;
    final status = ref.watch(governorStatusProvider).valueOrNull;
    final (color, label) = switch (connState) {
      HbpConnectionState.connected => (
          cs.primary,
          'RPi5: ${status?.tailscaleLatencyMs ?? 12}MS | ONLINE'
        ),
      HbpConnectionState.connecting => (Colors.amber, 'RPi5: CONNECTING...'),
      HbpConnectionState.reconnecting => (Colors.orange, 'RPi5: RETRYING...'),
      HbpConnectionState.disconnected => (cs.error, 'RPi5: OFFLINE'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1),
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
                letterSpacing: 0.8),
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
    final activeColor = cs.primary;

    return Tooltip(
      message: isExpanded ? '' : destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            border: isSelected
                ? Border.all(
                    color: activeColor.withValues(alpha: 0.4), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment:
                isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                color: isSelected ? activeColor : cs.onSurfaceVariant,
                size: 22,
              ),
              if (isExpanded)
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isExpanded ? 1.0 : 0.0,
                    curve: Curves.easeInOut,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        destination.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected ? activeColor : cs.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
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

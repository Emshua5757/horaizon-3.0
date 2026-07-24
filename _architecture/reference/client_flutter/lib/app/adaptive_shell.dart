import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_history.dart';
import 'package:client_flutter/core/governor/governor_metrics_provider.dart';

/// A mathematically responsive shell that wraps injected page content.
///
/// Uses [LayoutBuilder] to intercept GPU box constraints before the paint phase,
/// ensuring Zero-Layout-Shift (ZLS) when migrating between Mobile and Desktop form factors.
class AdaptiveShell extends ConsumerWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observe the O(1) route history state
    final routeHistory = ref.watch(routeHistoryProvider);

    // 2. Watch real-time governor metrics stream
    final metricsAsync = ref.watch(governorMetricsProvider);
    final metrics = metricsAsync.value;
    final cpuVal = metrics != null ? '${metrics.cpuPct.toStringAsFixed(0)}%' : '—%';
    final ramVal = metrics != null ? '${(metrics.ramMb / 1024.0).toStringAsFixed(1)}G' : '—G';
    final diskVal = metrics != null ? '${metrics.diskUsedPct.toStringAsFixed(0)}%' : '—%';

    return LayoutBuilder(
      builder: (context, constraints) {
        // 3. The ZLS Bifurcation Check (600px breakpoint)
        if (constraints.maxWidth < 600) {
          // ==============================
          // MOBILE CHASSIS
          // ==============================
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 120,
              actions: [
                _buildMobileStat(Icons.speed_rounded, cpuVal, Colors.orangeAccent),
                const SizedBox(width: 8),
                _buildMobileStat(Icons.memory_outlined, ramVal, Colors.tealAccent),
                const SizedBox(width: 8),
                _buildMobileStat(Icons.storage_rounded, diskVal, Colors.pinkAccent),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    if (routeHistory.currentLocation != null) {
                      context.go(routeHistory.currentLocation!);
                    }
                  },
                ),
              ],
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: routeHistory.canGoBack
                        ? () {
                            routeHistory.moveBack();
                            context.go(routeHistory.currentLocation!);
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: routeHistory.canGoForward
                        ? () {
                            routeHistory.moveForward();
                            context.go(routeHistory.currentLocation!);
                          }
                        : null,
                  ),
                ],
              ),
            ),
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _getSelectedIndex(context),
              onTap: (index) {
                if (index == 0) context.go('/dashboard');
                if (index == 1) context.go('/comms');
                if (index == 2) context.go('/console');
                if (index == 3) context.go('/settings');
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: 'Comms',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.terminal),
                  label: 'Console',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        } else {
          // ==============================
          // DESKTOP/TABLET CHASSIS
          // ==============================
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _getSelectedIndex(context),
                  onDestinationSelected: (index) {
                    if (index == 0) context.go('/dashboard');
                    if (index == 1) context.go('/comms');
                    if (index == 2) context.go('/console');
                    if (index == 3) context.go('/settings');
                  },
                  leading: Column(
                    children: [
                      const SizedBox(height: 16),
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: routeHistory.canGoBack
                            ? () {
                                routeHistory.moveBack();
                                context.go(routeHistory.currentLocation!);
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: routeHistory.canGoForward
                            ? () {
                                routeHistory.moveForward();
                                context.go(routeHistory.currentLocation!);
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          if (routeHistory.currentLocation != null) {
                            context.go(routeHistory.currentLocation!);
                          }
                        },
                      ),
                    ],
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatIcon(Icons.speed_rounded, cpuVal, Colors.orangeAccent),
                            _buildStatIcon(Icons.memory_outlined, ramVal, Colors.tealAccent),
                            _buildStatIcon(Icons.storage_rounded, diskVal, Colors.pinkAccent),
                          ],
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      label: Text('Comms'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.terminal),
                      label: Text('Console'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),

                // 3. Inject the active routed page into the remaining space
                Expanded(child: child),
              ],
            ),
          );
        }
      },
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/comms')) return 1;
    if (location.startsWith('/console')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0; // Default dashboard
  }

  Widget _buildMobileStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildStatIcon(IconData icon, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

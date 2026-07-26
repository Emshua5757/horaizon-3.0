import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Responsive persistent navigation shell.
/// - Wide (>= 600px): NavigationRail on the left side.
/// - Narrow (< 600px): NavigationBar at the bottom (Android/portrait).
class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  static const _destinations = [
    _Dest(icon: Icons.dashboard_outlined,  selected: Icons.dashboard,       label: 'Dashboard',  path: '/dashboard'),
    _Dest(icon: Icons.memory_outlined,     selected: Icons.memory,          label: 'Governor',   path: '/governor/status'),
    _Dest(icon: Icons.book_outlined,       selected: Icons.book,            label: 'Diary',      path: '/diary'),
    _Dest(icon: Icons.settings_outlined,   selected: Icons.settings,        label: 'Settings',   path: '/settings'),
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
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final isWide = MediaQuery.of(context).size.width >= 600;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => context.go(_destinations[i].path),
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Dest {
  final IconData icon;
  final IconData selected;
  final String label;
  final String path;
  const _Dest({required this.icon, required this.selected, required this.label, required this.path});
}

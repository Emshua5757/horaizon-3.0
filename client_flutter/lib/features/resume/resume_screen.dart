import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/resume_compile_screen.dart';
import 'screens/resume_editor_screen.dart';
import 'screens/resume_history_screen.dart';
import 'providers/resume_history_provider.dart';

// ---------------------------------------------------------------------------
// Tab index provider — used to allow programmatic tab switching
// ---------------------------------------------------------------------------

/// Local tab index for the ResumeScreen bottom nav.
/// Navigation between tabs is LOCAL state — NOT GoRouter push —
/// to preserve scroll position and avoid rebuild cost.
final _resumeTabIndexProvider = StateProvider<int>((ref) => 0);

/// ResumeScreen tab shell with Editor / Compile / History bottom nav.
///
/// Tab navigation is local (StatefulWidget index) — not GoRouter push.
class ResumeScreen extends ConsumerWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(_resumeTabIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [
          if (tabIndex == 2)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh history',
              onPressed: () => ref.invalidate(resumeHistoryProvider),
            ),
        ],
      ),
      body: IndexedStack(
        index: tabIndex,
        children: [
          const ResumeEditorScreen(),
          ResumeCompileScreen(
            onCompileSuccess: () =>
                ref.read(_resumeTabIndexProvider.notifier).state = 2,
          ),
          const ResumeHistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) =>
            ref.read(_resumeTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: 'Editor',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Compile',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

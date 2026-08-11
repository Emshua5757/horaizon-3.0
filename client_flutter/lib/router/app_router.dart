import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/chat/global_chat_screen.dart';
import '../features/terminal/terminal_screen.dart';
import '../features/diary/diary_screen.dart';
import '../features/diary/block_gallery_screen.dart';
import '../features/code_visualizer/code_topology_screen.dart';
import '../features/resume/resume_screen.dart';
import '../features/certifications/cert_dashboard_screen.dart';
import '../features/certifications/cert_roadmap_screen.dart';
import '../features/certifications/investment_summary_screen.dart';
import 'splash_screen.dart';
import 'shell_scaffold.dart';

final routeObserverProvider = Provider((_) => RouteObserver<ModalRoute<void>>());

/// GoRouter configuration with splash route and ShellRoute for the main app.
final routerProvider = Provider<GoRouter>((ref) {
  final observer = ref.watch(routeObserverProvider);

  return GoRouter(
    initialLocation: '/',
    observers: [observer],
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (_, __) => const GlobalChatScreen(),
          ),
          GoRoute(
            path: '/terminal',
            builder: (_, __) => const TerminalScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/diary',
            builder: (_, __) => const DiaryScreen(),
          ),
          GoRoute(
            path: '/code/topology',
            builder: (_, __) => const CodeTopologyScreen(),
          ),
          GoRoute(
            path: '/dev/blocks',
            builder: (_, __) => const BlockGalleryScreen(),
          ),
          GoRoute(
            path: '/resume',
            builder: (_, __) => const ResumeScreen(),
          ),
          GoRoute(
            path: '/certs',
            builder: (_, __) => const CertDashboardScreen(),
          ),
          GoRoute(
            path: '/certs/roadmap',
            builder: (_, __) => const CertRoadmapScreen(),
          ),
          GoRoute(
            path: '/certs/investments',
            builder: (_, __) => const InvestmentSummaryScreen(),
          ),
        ],
      ),
    ],
  );
});

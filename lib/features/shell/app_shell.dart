import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/widgets/language_switcher.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isAdmin = ref.watch(isAdminProvider);
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appName),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: LanguageSwitcherChip(),
          ),
          if (isAdmin)
            IconButton(
              tooltip: s.adminPanel,
              onPressed: () => context.go('/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: s.signOut,
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: child,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexForLocation(location),
        onDestinationSelected: (i) => context.go(_locationForIndex(i)),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.sports_soccer_outlined),
            selectedIcon: const Icon(Icons.sports_soccer),
            label: s.matches,
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: s.standings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: s.myStats,
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/leaderboard')) return 1;
    if (location.startsWith('/stats')) return 2;
    return 0;
  }

  String _locationForIndex(int index) {
    switch (index) {
      case 1:
        return '/leaderboard';
      case 2:
        return '/stats';
      default:
        return '/dashboard';
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:world_cup_predictor/core/constants/app_constants.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(appNameAr),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indexForLocation(location),
          onDestinationSelected: (i) => context.go(_locationForIndex(i)),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.sports_soccer_outlined),
              selectedIcon: Icon(Icons.sports_soccer),
              label: 'المباريات',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard),
              label: 'الترتيب',
            ),
            NavigationDestination(
              icon: Icon(Icons.visibility_outlined),
              selectedIcon: Icon(Icons.visibility),
              label: 'الطقطقة',
            ),
          ],
        ),
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/leaderboard')) return 1;
    if (location.startsWith('/insights')) return 2;
    return 0;
  }

  String _locationForIndex(int index) {
    switch (index) {
      case 1:
        return '/leaderboard';
      case 2:
        return '/insights';
      default:
        return '/dashboard';
    }
  }
}

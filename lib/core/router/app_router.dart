import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/core/config/auth_redirect.dart';
import 'package:world_cup_predictor/features/auth/auth_callback_page.dart';
import 'package:world_cup_predictor/features/admin/admin_page.dart';
import 'package:world_cup_predictor/features/auth/login_page.dart';
import 'package:world_cup_predictor/features/auth/profile_setup_page.dart';
import 'package:world_cup_predictor/features/dashboard/dashboard_page.dart';
import 'package:world_cup_predictor/features/leaderboard/leaderboard_page.dart';
import 'package:world_cup_predictor/features/shell/app_shell.dart';
import 'package:world_cup_predictor/features/stats/my_stats_page.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthRefreshListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isAuthCallbackUrl ? '/auth/callback' : '/dashboard',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loc = state.matchedLocation;
      final auth = ref.read(authServiceProvider);
      final profileAsync = ref.read(currentProfileProvider);

      if (isAuthCallbackUrl && loc != '/auth/callback') {
        return '/auth/callback';
      }

      if (session == null) {
        if (loc == '/login' || loc == '/auth/callback') return null;
        return '/login';
      }

      if (loc == '/auth/callback') {
        if (profileAsync.isLoading) return null;
        return auth.profileNeedsSetup(profileAsync.valueOrNull)
            ? '/profile-setup'
            : '/dashboard';
      }

      if (loc == '/login') {
        if (profileAsync.isLoading) return null;
        return auth.profileNeedsSetup(profileAsync.valueOrNull)
            ? '/profile-setup'
            : '/dashboard';
      }

      if (profileAsync.isLoading) return null;

      final needsProfile = auth.profileNeedsSetup(profileAsync.valueOrNull);
      if (needsProfile && loc != '/profile-setup') {
        return '/profile-setup';
      }

      if (!needsProfile && loc == '/profile-setup') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardPage(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const MyStatsPage(),
          ),
        ],
      ),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    ref.listen(authStateProvider, (_, __) {
      ref.invalidate(currentProfileProvider);
      notifyListeners();
    });
    ref.listen(currentProfileProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}

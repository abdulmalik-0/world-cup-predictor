import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/widgets/hero_video_banner.dart';
import 'package:world_cup_predictor/core/widgets/malaz_logo.dart';
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
    final activeIndex = _indexForLocation(location);
    final heroCollapse = ref.watch(heroCollapseProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        // Force LTR so the INVENU logo stays top-left in both languages.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xF2000000),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centre: the "26" clip — fades in as the dashboard hero
                // collapses on scroll, so the clip "lands" in the top bar.
                ValueListenableBuilder<double>(
                  valueListenable: heroCollapse,
                  builder: (context, p, _) {
                    final op = ((p - 0.55) / 0.45).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: op,
                      child: const IgnorePointer(child: WcMiniLogo(height: 42)),
                    );
                  },
                ),
                Row(
              children: [
                // Left: Malaz logo + small circular language toggle.
                const MalazLogo(height: 24),
                const SizedBox(width: 10),
                const LanguageSwitcherChip(),
                const Spacer(),
                // Section menu (replaces the old bottom nav).
                _NavLink(
                  label: s.matches,
                  active: activeIndex == 0,
                  onTap: () => context.go('/dashboard'),
                ),
                _NavLink(
                  label: s.standings,
                  active: activeIndex == 1,
                  onTap: () => context.go('/leaderboard'),
                ),
                _NavLink(
                  label: s.myStats,
                  active: activeIndex == 2,
                  onTap: () => context.go('/stats'),
                ),
                const SizedBox(width: 4),
                if (isAdmin)
                  IconButton(
                    tooltip: s.adminPanel,
                    onPressed: () => context.go('/admin'),
                    icon: const Icon(Icons.admin_panel_settings_outlined,
                        color: Colors.white70),
                  ),
                IconButton(
                  tooltip: s.signOut,
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.white70),
                ),
              ],
                ),
              ],
            ),
          ),
        ),
      ),
      // Dashboard spans full width; other pages stay capped at 680.
      body: location.startsWith('/dashboard')
          ? child
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: child,
              ),
            ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/leaderboard')) return 1;
    if (location.startsWith('/stats')) return 2;
    return 0;
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFFE9B84A) : Colors.white,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 2.5,
              width: active ? 22 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFFE9B84A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

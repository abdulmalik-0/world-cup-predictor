import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/widgets/hero_video_banner.dart';
import 'package:world_cup_predictor/core/widgets/invenu_logo.dart';
import 'package:world_cup_predictor/core/widgets/language_switcher.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

const double _navHeight = 66;

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isAdmin = ref.watch(isAdminProvider);
    final s = S.of(context);
    final activeIndex = _indexForLocation(location);
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 720;
    final isDashboard = location.startsWith('/dashboard');
    // The "26" clip morphs into the navbar only on the dashboard (desktop).
    final showMorph = isDashboard && !isCompact;

    final pageBody = isDashboard
        ? child
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: child,
            ),
          );

    return Scaffold(
      body: Stack(
        children: [
          // 0) White hero backdrop (dashboard): behind the "26" clip at the
          //    top, fades out as you scroll so the dark content takes over.
          if (showMorph)
            Positioned.fill(
              top: _navHeight,
              child: ValueListenableBuilder<double>(
                valueListenable: ref.watch(heroCollapseProvider),
                builder: (context, t, _) {
                  final op = (1 - t / 0.7).clamp(0.0, 1.0);
                  return IgnorePointer(
                    child: Opacity(
                      opacity: op,
                      child: const ColoredBox(color: Colors.white),
                    ),
                  );
                },
              ),
            ),

          // 1) Page content, pushed below the fixed navbar.
          Positioned.fill(
            top: _navHeight,
            child: pageBody,
          ),

          // 2) Fixed top navigation bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _navHeight,
            child: _NavBar(
              s: s,
              activeIndex: activeIndex,
              isCompact: isCompact,
              isAdmin: isAdmin,
              // On compact (phone) we keep a small static clip inline; on
              // desktop the morphing overlay handles it, so leave a gap.
              showInlineClip: isDashboard && isCompact,
              onSignOut: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ),

          // 3) The morphing "26" video clip — drawn ON TOP so it lands cleanly
          //    in the centre of the navbar. Flies from a big hero in the middle
          //    of the screen up into the navbar as you scroll, and back down as
          //    you scroll up. (Desktop dashboard only.)
          if (showMorph)
            _MorphingClip(
              collapse: ref.watch(heroCollapseProvider),
              screenW: size.width,
              screenH: size.height,
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
}

/// The masked "26" clip whose size + position interpolate with scroll.
class _MorphingClip extends StatelessWidget {
  const _MorphingClip({
    required this.collapse,
    required this.screenW,
    required this.screenH,
  });

  final ValueNotifier<double> collapse;
  final double screenW;
  final double screenH;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: collapse,
      builder: (context, raw, _) {
        final t = Curves.easeInOutCubic.transform(raw.clamp(0.0, 1.0));

        // Clip aspect (width / height) of the "26 NY NJ" shape.
        const aspect = 2.55;
        const smallH = 46.0;
        final bodyH = screenH - _navHeight;
        // Big size: fills most of the width but capped by the body height.
        final bigH = (screenW * 0.78 / aspect).clamp(120.0, bodyH * 0.52);

        final h = _lerp(bigH, smallH, t);
        final w = h * aspect;

        final cx = screenW / 2;
        final bigCy = _navHeight + bodyH * 0.42; // a touch above centre
        const smallCy = _navHeight / 2;
        final cy = _lerp(bigCy, smallCy, t);

        return Positioned(
          left: cx - w / 2,
          top: cy - h / 2,
          width: w,
          height: h,
          child: IgnorePointer(child: WcMiniLogo(height: h)),
        );
      },
    );
  }
}

class _NavBar extends ConsumerWidget {
  const _NavBar({
    required this.s,
    required this.activeIndex,
    required this.isCompact,
    required this.isAdmin,
    required this.showInlineClip,
    required this.onSignOut,
  });

  final S s;
  final int activeIndex;
  final bool isCompact;
  final bool isAdmin;
  final bool showInlineClip;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xF2000000),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const InvenuLogo(height: 30),
            const SizedBox(width: 10),
            const LanguageSwitcherChip(),
            const Spacer(),
            // Centre gap — the morphing clip lands here on desktop. On phone
            // we show a small static clip inline.
            if (showInlineClip) const IgnorePointer(child: WcMiniLogo(height: 40)),
            const Spacer(),
            if (!isCompact) ...[
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
            ] else ...[
              PopupMenuButton<int>(
                tooltip: s.matches,
                color: const Color(0xFF0A0A0A),
                icon: const Icon(Icons.menu, color: Colors.white),
                onSelected: (i) => context.go(_locationForIndex(i)),
                itemBuilder: (_) => [
                  _menuItem(0, s.matches, Icons.sports_soccer_outlined,
                      activeIndex == 0),
                  _menuItem(1, s.standings, Icons.leaderboard_outlined,
                      activeIndex == 1),
                  _menuItem(2, s.myStats, Icons.insights_outlined,
                      activeIndex == 2),
                ],
              ),
            ],
            if (isAdmin)
              IconButton(
                tooltip: s.adminPanel,
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined,
                    color: Colors.white70),
              ),
            IconButton(
              tooltip: s.signOut,
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  String _locationForIndex(int i) {
    switch (i) {
      case 1:
        return '/leaderboard';
      case 2:
        return '/stats';
      default:
        return '/dashboard';
    }
  }

  PopupMenuItem<int> _menuItem(
      int value, String label, IconData icon, bool active) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: active ? const Color(0xFFE9B84A) : Colors.white70),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFFE9B84A) : Colors.white,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

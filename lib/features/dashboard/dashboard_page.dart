import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/services/hero_video_service.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/core/widgets/grab_scroll.dart';
import 'package:world_cup_predictor/core/widgets/hero_video_banner.dart';
import 'package:world_cup_predictor/core/widgets/match_day_header.dart';
import 'package:world_cup_predictor/core/widgets/scoring_rules_card.dart';
import 'package:world_cup_predictor/features/dashboard/widgets/match_card.dart';
import 'package:world_cup_predictor/features/dashboard/widgets/match_predictions_sheet.dart';
import 'package:world_cup_predictor/models/match.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  /// `null` = all days; otherwise `yyyy-MM-dd`.
  String? _selectedDayKey;

  final ScrollController _scroll = ScrollController();
  double _heroMax = 1.0;

  // Smooth (inertia/lerp) scrolling for mouse wheel + trackpad.
  Ticker? _smoothTicker;
  double _smoothTarget = 0.0;

  // Cached reference so dispose / scroll listener never touch `ref` (which is
  // illegal after the element becomes inactive, e.g. when locale changes).
  ValueNotifier<double>? _heroCollapse;

  @override
  void initState() {
    super.initState();
    _heroCollapse = ref.read(heroCollapseProvider);
    // Touch the shared service so it kicks off init (idempotent).
    ref.read(heroVideoServiceProvider);
    _scroll.addListener(_onScroll);
    _smoothTicker = createTicker(_onSmoothTick);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final base = (_smoothTicker?.isActive ?? false)
        ? _smoothTarget
        : _scroll.offset;
    _smoothTarget = (base + event.scrollDelta.dy).clamp(0.0, max);
    if (!(_smoothTicker?.isActive ?? false)) _smoothTicker?.start();
  }

  void _onSmoothTick(Duration _) {
    if (!_scroll.hasClients) {
      _smoothTicker?.stop();
      return;
    }
    final max = _scroll.position.maxScrollExtent;
    _smoothTarget = _smoothTarget.clamp(0.0, max);
    final cur = _scroll.offset;
    final diff = _smoothTarget - cur;
    if (diff.abs() < 0.4) {
      _scroll.jumpTo(_smoothTarget);
      _smoothTicker?.stop();
      return;
    }
    // Ease toward the target — lower factor = smoother/slower glide.
    _scroll.jumpTo(cur + diff * 0.16);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = (_scroll.offset / _heroMax).clamp(0.0, 1.0);
    _heroCollapse?.value = p;
  }


  void _onPointerDrag(double dy) {
    if (!_scroll.hasClients || dy == 0) return;
    _smoothTicker?.stop();
    final max = _scroll.position.maxScrollExtent;
    final o = (_scroll.offset - dy).clamp(0.0, max);
    _scroll.jumpTo(o);
    _smoothTarget = o;
  }

  @override
  void dispose() {
    _smoothTicker?.dispose();
    _scroll.removeListener(_onScroll);
    // Reset so other pages' nav bar doesn't show the clip. Uses the cached
    // notifier directly — do NOT call `ref.read` here (the element is already
    // inactive during dispose, which would assert in framework).
    _heroCollapse?.value = 0.0;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(upcomingMatchesProvider);
    final predictionsAsync = ref.watch(myPredictionsProvider);
    final user = ref.watch(supabaseClientProvider).auth.currentUser;
    // Keep the shared video alive (the morphing clip in the shell renders it).
    ref.watch(heroVideoServiceProvider);
    final heroCollapse = ref.watch(heroCollapseProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(upcomingMatchesProvider);
        ref.invalidate(myPredictionsProvider);
      },
      child: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ في تحميل المباريات: $e')),
        data: (matches) {
          final predictions = predictionsAsync.valueOrNull ?? {};
          final s = S.of(context);
          final lang = Localizations.localeOf(context).languageCode;

          // Soonest upcoming match (matches are sorted by kickoff ascending).
          final now = DateTime.now();
          Match? nextMatch;
          for (final m in matches) {
            if (m.kickoffAt.isAfter(now)) {
              nextMatch = m;
              break;
            }
          }
          final nextTitle = nextMatch == null
              ? null
              : '${nextMatch.homeTeamEn ?? nextMatch.homeTeam} × ${nextMatch.awayTeamEn ?? nextMatch.awayTeam}';

          if (matches.isEmpty) {
            return GrabScrollListView(
              children: [
                const SizedBox(height: 120),
                const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(s.noMatches, textAlign: TextAlign.center),
              ],
            );
          }

          final dayFmt = DateFormat('yyyy-MM-dd');
          final days = _uniqueDays(matches, dayFmt);

          // Reset filter if selected day no longer has matches.
          if (_selectedDayKey != null &&
              !days.any((d) => d.key == _selectedDayKey)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedDayKey = null);
            });
          }

          final filtered = _selectedDayKey == null
              ? matches
              : matches
                  .where((m) => dayFmt.format(m.kickoffAt) == _selectedDayKey)
                  .toList();

          final showDayHeaders = _selectedDayKey == null;
          final children = <Widget>[];
          String? lastDay;
          var animIndex = 0;

          if (filtered.isEmpty) {
            children.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text(s.noMatchesThisDay)),
              ),
            );
          } else {
            for (final match in filtered) {
              final dayKey = dayFmt.format(match.kickoffAt);
              if (showDayHeaders && dayKey != lastDay) {
                lastDay = dayKey;
                final count = filtered
                    .where((m) => dayFmt.format(m.kickoffAt) == dayKey)
                    .length;
                children.add(
                  MatchDayHeader(date: match.kickoffAt, count: count)
                      .animate()
                      .fadeIn(delay: (animIndex * 50).ms, duration: 300.ms),
                );
              }
              children.add(
                MatchCard(
                  match: match,
                  prediction: predictions[match.id],
                  onViewPredictions: () => showMatchPredictionsSheet(
                    context: context,
                    ref: ref,
                    match: match,
                  ),
                  onSave: (home, away) async {
                    if (user == null) return;
                    final service = ref.read(matchServiceProvider);
                    final existing = predictions[match.id];
                    await service.savePrediction(
                      userId: user.id,
                      matchId: match.id,
                      homeScore: home,
                      awayScore: away,
                      existing: existing,
                    );
                    ref.invalidate(myPredictionsProvider);
                  },
                )
                    .animate()
                    .fadeIn(delay: (animIndex * 50).ms, duration: 320.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
              );
              animIndex++;
            }
          }

          final listItems = <Widget>[
            if (nextMatch != null) ...[
              MatchCountdownBar(
                kickoff: nextMatch.kickoffAt,
                title: nextTitle,
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 18),
            ],
            const ScoringRulesCard(),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 24))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.18, duration: 900.ms, curve: Curves.easeInOut)
                    .rotate(begin: -0.04, end: 0.04, duration: 900.ms),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.upcomingMatches,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.12, end: 0, curve: Curves.easeOut)
                .then()
                .shimmer(duration: 1400.ms, color: const Color(0xFFE8B23A)),
            const SizedBox(height: 8),
            Text(
              s.predictionHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _DayFilterBar(
              days: days,
              selectedKey: _selectedDayKey,
              allDaysLabel: s.allDays,
              lang: lang,
              onSelected: (key) => setState(() => _selectedDayKey = key),
            ),
            const SizedBox(height: 8),
            ...children,
            const SizedBox(height: 24),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final bodyH = constraints.maxHeight;
              final isCompact = constraints.maxWidth < 720;
              // Distance over which the hero transitions. The top spacer is the
              // same height, so the page opens on the big clip and content
              // rises into place as the transition completes.
              final heroExtent =
                  ((isCompact ? bodyH * 0.62 : bodyH * 0.82)).clamp(300.0, 760.0);
              _heroMax = heroExtent;
              final contentPad =
                  ((constraints.maxWidth - 680) / 2).clamp(16.0, 600.0);

              final scrollView = ScrollConfiguration(
                behavior: const GrabScrollBehavior(),
                child: Listener(
                  onPointerSignal: _onPointerSignal,
                  onPointerMove: (event) {
                    if (event.buttons == 0) return;
                    _onPointerDrag(event.delta.dy);
                  },
                  child: CustomScrollView(
                    controller: _scroll,
                    physics: const NeverScrollableScrollPhysics(),
                    slivers: [
                      // Transparent spacer: opens on the hero (fixed video on
                      // mobile / morphing clip on desktop) shown behind it.
                      SliverToBoxAdapter(child: SizedBox(height: heroExtent)),
                      // Solid content that rises and covers the hero.
                      SliverToBoxAdapter(
                        child: Container(
                          color: const Color(0xFF050505),
                          padding: EdgeInsets.fromLTRB(
                              contentPad, 18, contentPad, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: listItems,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (isCompact) {
                // MOBILE: fixed masked-video hero pinned in the background;
                // the content (scrollView) slides up OVER it as a smooth
                // parallax overlay.
                return Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: WcMaskedHero(collapse: heroCollapse),
                      ),
                    ),
                    scrollView,
                  ],
                );
              }
              // DESKTOP: the shell draws the white backdrop + morphing clip.
              return scrollView;
            },
          );
        },
      ),
    );
  }

  List<({String key, DateTime date})> _uniqueDays(
    List<Match> matches,
    DateFormat dayFmt,
  ) {
    final seen = <String>{};
    final days = <({String key, DateTime date})>[];
    for (final m in matches) {
      final key = dayFmt.format(m.kickoffAt);
      if (seen.add(key)) {
        days.add((key: key, date: m.kickoffAt));
      }
    }
    return days;
  }
}

class _DayFilterBar extends StatelessWidget {
  const _DayFilterBar({
    required this.days,
    required this.selectedKey,
    required this.allDaysLabel,
    required this.lang,
    required this.onSelected,
  });

  final List<({String key, DateTime date})> days;
  final String? selectedKey;
  final String allDaysLabel;
  final String lang;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final chipFmt = DateFormat('EEE d/M', lang);

    return GrabScrollHorizontal(
      child: Row(
        children: [
          _DayChip(
            label: allDaysLabel,
            selected: selectedKey == null,
            onTap: () => onSelected(null),
          ),
          for (final day in days) ...[
            const SizedBox(width: 8),
            _DayChip(
              label: chipFmt.format(day.date),
              selected: selectedKey == day.key,
              onTap: () => onSelected(day.key),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.35),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        color: selected ? AppTheme.pitchGreen : null,
      ),
      side: BorderSide(
        color: selected
            ? AppTheme.pitchGreen
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
      ),
    );
  }
}

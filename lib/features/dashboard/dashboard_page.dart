import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
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

class _DashboardPageState extends ConsumerState<DashboardPage> {
  /// `null` = all days; otherwise `yyyy-MM-dd`.
  String? _selectedDayKey;

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(upcomingMatchesProvider);
    final predictionsAsync = ref.watch(myPredictionsProvider);
    final user = ref.watch(supabaseClientProvider).auth.currentUser;

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

          if (matches.isEmpty) {
            return ListView(
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                s.upcomingMatches,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const ScoringRulesCard(),
              const SizedBox(height: 12),
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
            ],
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

class _DayFilterBar extends StatefulWidget {
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
  State<_DayFilterBar> createState() => _DayFilterBarState();
}

class _DayFilterBarState extends State<_DayFilterBar> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _dragScroll(double deltaDx) {
    if (!_scrollController.hasClients || deltaDx == 0) return;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final dx = isRtl ? -deltaDx : deltaDx;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(
      (_scrollController.offset - dx).clamp(0.0, max),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chipFmt = DateFormat('EEE d/M', widget.lang);

    return ScrollConfiguration(
      behavior: const _GrabScrollBehavior(),
      child: Listener(
        onPointerMove: (event) {
          if (event.buttons == 0) return;
          _dragScroll(event.delta.dx);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Row(
            children: [
              _DayChip(
                label: widget.allDaysLabel,
                selected: widget.selectedKey == null,
                onTap: () => widget.onSelected(null),
              ),
              for (final day in widget.days) ...[
                const SizedBox(width: 8),
                _DayChip(
                  label: chipFmt.format(day.date),
                  selected: widget.selectedKey == day.key,
                  onTap: () => widget.onSelected(day.key),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Enables click-and-drag scrolling on web/desktop (mouse) as well as touch.
class _GrabScrollBehavior extends MaterialScrollBehavior {
  const _GrabScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
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

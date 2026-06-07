import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/features/dashboard/widgets/match_card.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          // Group matches by calendar day.
          final dayFmt = DateFormat('yyyy-MM-dd');
          final children = <Widget>[];
          String? lastDay;
          var animIndex = 0;

          for (final match in matches) {
            final dayKey = dayFmt.format(match.kickoffAt);
            if (dayKey != lastDay) {
              lastDay = dayKey;
              final count =
                  matches.where((m) => dayFmt.format(m.kickoffAt) == dayKey).length;
              children.add(
                _DayHeader(date: match.kickoffAt, count: count)
                    .animate()
                    .fadeIn(delay: (animIndex * 50).ms, duration: 300.ms),
              );
            }
            children.add(
              MatchCard(
                match: match,
                prediction: predictions[match.id],
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
              Text(
                s.predictionHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          );
        },
      ),
    );
  }
}

/// A date header that separates each day's matches.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.count});

  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final weekday = DateFormat('EEEE', lang).format(date);
    final fullDate = DateFormat('d MMMM yyyy', lang).format(date);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weekday,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                fullDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              S.of(context).matchesCount(count),
              style: const TextStyle(
                color: AppTheme.pitchGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

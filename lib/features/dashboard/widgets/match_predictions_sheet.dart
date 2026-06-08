import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/core/utils/prediction_window.dart';
import 'package:world_cup_predictor/models/match.dart';
import 'package:world_cup_predictor/models/match_prediction_entry.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

Future<void> showMatchPredictionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Match match,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) =>
          _MatchPredictionsBody(match: match, scrollController: scrollController),
    ),
  );
}

class _MatchPredictionsBody extends ConsumerWidget {
  const _MatchPredictionsBody({
    required this.match,
    required this.scrollController,
  });

  final Match match;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final locked = !isPredictionOpen(match.kickoffAt);
    final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final async = ref.watch(matchPredictionsProvider(match.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.colleaguePredictions,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            s.ar
                ? '${match.homeTeam} × ${match.awayTeam}'
                : '${match.homeTeamEn} × ${match.awayTeamEn}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (!locked) ...[
            const SizedBox(height: 12),
            _InfoBanner(
              icon: Icons.lock_clock,
              text: s.predictionsHiddenUntilLock,
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(s.errLoadPredictions, textAlign: TextAlign.center),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(child: Text(s.noPredictionsYet));
                }
                return ListView.separated(
                  controller: scrollController,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isMe = entry.prediction.userId == currentUserId;
                    return _PredictionRow(
                      entry: entry,
                      isMe: isMe,
                      showPoints: match.isFinished,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.pitchGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.pitchGreen,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  const _PredictionRow({
    required this.entry,
    required this.isMe,
    required this.showPoints,
  });

  final MatchPredictionEntry entry;
  final bool isMe;
  final bool showPoints;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final p = entry.prediction;
    final name = entry.fullName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isMe
            ? AppTheme.pitchGreen.withValues(alpha: 0.25)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          initial,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isMe ? AppTheme.pitchGreen : null,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              entry.fullName,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.pitchGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.youLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pitchGreen,
                ),
              ),
            ),
        ],
      ),
      subtitle: entry.department.isNotEmpty ? Text(entry.department) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${p.homeScore} : ${p.awayScore}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (showPoints && p.pointsEarned != null)
            Text(
              s.points(p.pointsEarned!),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w700,
                  ),
            ),
        ],
      ),
    );
  }
}

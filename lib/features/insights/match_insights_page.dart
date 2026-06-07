import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/core/utils/prediction_window.dart';
import 'package:world_cup_predictor/core/widgets/team_badge.dart';
import 'package:world_cup_predictor/models/match.dart';
import 'package:world_cup_predictor/models/prediction.dart';
import 'package:world_cup_predictor/models/prediction_history.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

class MatchInsightsPage extends ConsumerWidget {
  const MatchInsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(upcomingMatchesProvider);
    final finishedAsync = ref.watch(finishedMatchesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(upcomingMatchesProvider);
        ref.invalidate(finishedMatchesProvider);
      },
      child: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (upcoming) {
          final finished = finishedAsync.valueOrNull ?? [];
          final lockedUpcoming =
              upcoming.where((m) => !isPredictionOpen(m.kickoffAt)).toList();
          final insightMatches = [...lockedUpcoming, ...finished];

          if (insightMatches.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Icon(Icons.hourglass_empty, size: 64),
                SizedBox(height: 16),
                Text(
                  'ستظهر توقعات الزملاء هنا بعد إغلاق وقت التوقع',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: insightMatches.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سجل الشفافية والطقطقة',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'بعد إغلاق التوقعات يمكنك رؤية توقعات الجميع — ومن عدّل توقعه!',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }

              final match = insightMatches[index - 1];
              return _MatchInsightsCard(match: match);
            },
          );
        },
      ),
    );
  }
}

class _MatchInsightsCard extends ConsumerStatefulWidget {
  const _MatchInsightsCard({required this.match});

  final Match match;

  @override
  ConsumerState<_MatchInsightsCard> createState() => _MatchInsightsCardState();
}

class _MatchInsightsCardState extends ConsumerState<_MatchInsightsCard> {
  List<Prediction>? _predictions;
  Map<String, List<PredictionHistoryEntry>>? _historyMap;
  Map<String, String>? _names;
  bool _loading = false;
  bool _expanded = false;

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final service = ref.read(matchServiceProvider);
      final client = ref.read(supabaseClientProvider);

      final predictions = await service.fetchMatchPredictions(widget.match.id);
      final history = await service.fetchMatchHistoryMap(widget.match.id);

      final userIds = predictions.map((p) => p.userId).toSet();
      final names = <String, String>{};

      if (userIds.isNotEmpty) {
        final profiles = await client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', userIds.toList());

        for (final row in profiles as List) {
          names[row['id'] as String] = row['full_name'] as String;
        }
      }

      setState(() {
        _predictions = predictions;
        _historyMap = history;
        _names = names;
        _expanded = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: MatchTeamsHeader(match: match),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                match.isFinished && match.homeScore != null
                    ? 'النتيجة: ${match.homeScore}-${match.awayScore}'
                    : 'التوقعات مغلقة — بانتظار المباراة',
              ),
            ),
            trailing: match.isArabTeamMatch
                ? const Chip(
                    label: Text('دبل 🔥', style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.arabBadgeOrange,
                  )
                : null,
            onTap: _expanded ? null : _load,
          ),
          if (!_expanded)
            TextButton(onPressed: _load, child: const Text('عرض التوقعات'))
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (_predictions == null || _predictions!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا توجد توقعات لهذه المباراة'),
            )
          else
            ..._predictions!.map((p) {
              final history = _historyMap?[p.id] ?? [];
              final name = _names?[p.userId] ?? 'موظف';
              return _PredictionInsightTile(
                name: name,
                prediction: p,
                history: history,
                matchKickoff: match.kickoffAt,
              );
            }),
        ],
      ),
    );
  }
}

class _PredictionInsightTile extends StatelessWidget {
  const _PredictionInsightTile({
    required this.name,
    required this.prediction,
    required this.history,
    required this.matchKickoff,
  });

  final String name;
  final Prediction prediction;
  final List<PredictionHistoryEntry> history;
  final DateTime matchKickoff;

  @override
  Widget build(BuildContext context) {
    final hasEdits = history.isNotEmpty;

    return ListTile(
      dense: true,
      title: Row(
        children: [
          Expanded(child: Text(name)),
          Text(
            '${prediction.homeScore}-${prediction.awayScore}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (prediction.pointsEarned != null) ...[
            const SizedBox(width: 8),
            Text(
              '+${prediction.pointsEarned}',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ],
      ),
      trailing: hasEdits
          ? IconButton(
              tooltip: 'سجل التعديلات',
              icon: const Icon(Icons.edit_note, color: AppTheme.arabBadgeOrange),
              onPressed: () => _showHistory(context),
            )
          : null,
    );
  }

  void _showHistory(BuildContext context) {
    final closesAt = predictionClosesAt(matchKickoff);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعديلات $name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...history.map((h) {
                final minsBeforeLock = closesAt.difference(h.changedAt).inMinutes;
                final lockNote = minsBeforeLock >= 0
                    ? 'قبل قفل التوقع بـ $minsBeforeLock دقيقة'
                    : 'بعد قفل التوقع';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'عدّل توقعه من ${h.oldHomeScore}-${h.oldAwayScore} '
                    'إلى ${h.newHomeScore}-${h.newAwayScore} — $lockNote',
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

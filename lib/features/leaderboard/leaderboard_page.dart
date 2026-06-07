import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/models/leaderboard_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    _channel?.unsubscribe();
    _channel = ref.read(leaderboardServiceProvider).subscribe(() {
      ref.invalidate(leaderboardProvider);
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(leaderboardProvider),
      child: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Text('لا يوجد مشاركون بعد', textAlign: TextAlign.center),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'الترتيب اللحظي — يتحدّث تلقائياً',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                );
              }

              final entry = entries[index - 1];
              return _LeaderboardTile(rank: index, entry: entry);
            },
          );
        },
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (rank) {
      1 => AppTheme.accentGold,
      2 => Colors.grey.shade300,
      3 => const Color(0xFFCD7F32),
      _ => null,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medalColor ?? Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: medalColor != null ? Colors.black : null,
            ),
          ),
        ),
        title: Text(
          entry.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${entry.department} • ${entry.predictionsMade} توقع'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalPoints}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
            ),
            const Text('نقطة', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

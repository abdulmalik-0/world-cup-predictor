import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/theme/app_theme.dart';
import 'package:world_cup_predictor/models/leaderboard_entry.dart';
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
              children: [
                const SizedBox(height: 140),
                const Icon(Icons.emoji_events_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(S.of(context).noParticipants,
                    textAlign: TextAlign.center),
              ],
            );
          }

          final podium = entries.take(3).toList();
          final rest = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _LiveHeader(),
              const SizedBox(height: 16),
              if (podium.length == 3) _Podium(top: podium) else
                ...podium.asMap().entries.map(
                      (e) => _LeaderboardTile(rank: e.key + 1, entry: e.value),
                    ),
              if (rest.isNotEmpty) const SizedBox(height: 8),
              ...rest.asMap().entries.map(
                    (e) => _LeaderboardTile(rank: e.key + 4, entry: e.value),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppTheme.pitchGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          S.of(context).liveStandings,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top});

  final List<LeaderboardEntry> top;

  @override
  Widget build(BuildContext context) {
    // Visual order: 2nd, 1st, 3rd
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.accentGold.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _PodiumSpot(rank: 2, entry: top[1], height: 96)),
          Expanded(child: _PodiumSpot(rank: 1, entry: top[0], height: 124)),
          Expanded(child: _PodiumSpot(rank: 3, entry: top[2], height: 76)),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.rank,
    required this.entry,
    required this.height,
  });

  final int rank;
  final LeaderboardEntry entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = _medalColor(rank) ?? AppTheme.primaryGreen;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1)
          const Icon(Icons.emoji_events, color: AppTheme.accentGold, size: 26),
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 4),
          child: CircleAvatar(
            radius: rank == 1 ? 30 : 24,
            backgroundColor: color,
            child: Text(
              _initials(entry.fullName),
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: rank == 1 ? 20 : 16,
              ),
            ),
          ),
        ),
        Text(
          entry.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        Text(
          '${entry.totalPoints} ${S.of(context).pts}',
          style: const TextStyle(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w800,
              fontSize: 12),
        ),
        if (entry.finishedPredictions > 0) ...[
          const SizedBox(height: 2),
          Text(
            S.of(context).leaderboardRates(
              entry.correctPercent,
              entry.exactPercent,
            ),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 6),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.45)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardSubtitle extends StatelessWidget {
  const _LeaderboardSubtitle({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${entry.department} • ${s.predictionsMadeCount(entry.predictionsMade)}',
        ),
        const SizedBox(height: 2),
        Text(
          entry.finishedPredictions == 0
              ? s.leaderboardNoRatesYet
              : s.leaderboardRates(entry.correctPercent, entry.exactPercent),
          style: TextStyle(
            color: AppTheme.pitchGreen.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _medalColor(rank) ??
              Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _medalColor(rank) != null ? Colors.black : null,
            ),
          ),
        ),
        title: Text(
          entry.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: _LeaderboardSubtitle(entry: entry),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalPoints}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentGold,
                  ),
            ),
            Text(S.of(context).pts, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

Color? _medalColor(int rank) => switch (rank) {
      1 => AppTheme.accentGold,
      2 => const Color(0xFFC0C7D1),
      3 => const Color(0xFFCD7F32),
      _ => null,
    };

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first;
  return parts.first.characters.first + parts.elementAt(1).characters.first;
}

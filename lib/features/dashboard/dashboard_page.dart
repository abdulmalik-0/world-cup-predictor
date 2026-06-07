import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

          if (matches.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Icon(Icons.event_busy, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد مباريات قادمة حالياً',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'المباريات القادمة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'يُغلق التوقع قبل صافرة البداية بـ 15 دقيقة • مباريات العرب = نقاط مضاعفة 🔥',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ...matches.map(
                (match) => MatchCard(
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

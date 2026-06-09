import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/models/leaderboard_entry.dart';
import 'package:world_cup_predictor/models/match.dart';
import 'package:world_cup_predictor/models/match_prediction_entry.dart';
import 'package:world_cup_predictor/models/my_stats.dart';
import 'package:world_cup_predictor/models/prediction.dart';
import 'package:world_cup_predictor/models/profile.dart';
import 'package:world_cup_predictor/services/auth_service.dart';
import 'package:world_cup_predictor/services/match_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Dashboard hero collapse progress: 0 = full-screen clip, 1 = fully collapsed.
/// The dashboard updates it on scroll; the top nav bar shows the mini "26"
/// clip in its centre as it approaches 1.
final heroCollapseProvider = Provider<ValueNotifier<double>>((ref) {
  final notifier = ValueNotifier<double>(0.0);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final authServiceProvider = Provider(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);

final matchServiceProvider = Provider(
  (ref) => MatchService(ref.watch(supabaseClientProvider)),
);

final leaderboardServiceProvider = Provider(
  (ref) => LeaderboardService(ref.watch(supabaseClientProvider)),
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).getCurrentProfile();
});

final upcomingMatchesProvider = FutureProvider<List<Match>>((ref) async {
  return ref.watch(matchServiceProvider).fetchUpcomingMatches();
});

final matchPredictionsProvider = FutureProvider.autoDispose
    .family<List<MatchPredictionEntry>, String>((ref, matchId) {
  return ref.watch(matchServiceProvider).fetchMatchPredictionsWithProfiles(matchId);
});

final myPredictionsProvider =
    FutureProvider<Map<String, Prediction>>((ref) async {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return {};
  return ref.watch(matchServiceProvider).fetchMyPredictions(user.id);
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  return ref.watch(leaderboardServiceProvider).fetchLeaderboard();
});

final finishedMatchesProvider = FutureProvider<List<Match>>((ref) async {
  return ref.watch(matchServiceProvider).fetchFinishedMatches();
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentProfileProvider).valueOrNull?.isAdmin ?? false;
});

final allMatchesProvider = FutureProvider<List<Match>>((ref) async {
  return ref.watch(matchServiceProvider).fetchAllMatches();
});

final myStatsProvider = FutureProvider<MyStats>((ref) async {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return MyStats.empty();
  final rows =
      await ref.watch(matchServiceProvider).fetchMyPredictionsWithMatches(user.id);
  return MyStats.fromRows(rows);
});

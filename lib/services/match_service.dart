import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/models/leaderboard_entry.dart';
import 'package:world_cup_predictor/models/match.dart';
import 'package:world_cup_predictor/models/match_prediction_entry.dart';
import 'package:world_cup_predictor/models/prediction.dart';
import 'package:world_cup_predictor/models/prediction_history.dart';

class MatchService {
  MatchService(this._client);

  final SupabaseClient _client;

  Future<List<Match>> fetchUpcomingMatches() async {
    final rows = await _client
        .from('matches')
        .select()
        .inFilter('status', ['scheduled', 'live'])
        .order('kickoff_at', ascending: true);

    return (rows as List)
        .map((e) => Match.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Match>> fetchFinishedMatches() async {
    final rows = await _client
        .from('matches')
        .select()
        .eq('status', 'finished')
        .order('kickoff_at', ascending: false)
        .limit(20);

    return (rows as List)
        .map((e) => Match.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, Prediction>> fetchMyPredictions(String userId) async {
    final rows = await _client
        .from('predictions')
        .select()
        .eq('user_id', userId);

    final map = <String, Prediction>{};
    for (final row in rows as List) {
      final p = Prediction.fromJson(row as Map<String, dynamic>);
      map[p.matchId] = p;
    }
    return map;
  }

  Future<Prediction> savePrediction({
    required String userId,
    required String matchId,
    required int homeScore,
    required int awayScore,
    Prediction? existing,
  }) async {
    if (existing == null) {
      final data = await _client
          .from('predictions')
          .insert(
            Prediction(
              id: '',
              userId: userId,
              matchId: matchId,
              homeScore: homeScore,
              awayScore: awayScore,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ).toInsertJson(
              userId: userId,
              matchId: matchId,
              homeScore: homeScore,
              awayScore: awayScore,
            ),
          )
          .select()
          .single();
      return Prediction.fromJson(data);
    }

    final data = await _client
        .from('predictions')
        .update(existing.toUpdateJson(
          homeScore: homeScore,
          awayScore: awayScore,
        ))
        .eq('id', existing.id)
        .select()
        .single();

    return Prediction.fromJson(data);
  }

  Future<List<Prediction>> fetchMatchPredictions(String matchId) async {
    final rows = await _client
        .from('predictions')
        .select()
        .eq('match_id', matchId)
        .order('updated_at', ascending: false);

    return (rows as List)
        .map((e) => Prediction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Predictions for a match with employee name and department.
  Future<List<MatchPredictionEntry>> fetchMatchPredictionsWithProfiles(
    String matchId,
  ) async {
    final rows = await _client
        .from('predictions')
        .select('*, profiles(full_name, department)')
        .eq('match_id', matchId)
        .order('updated_at', ascending: false);

    final entries = (rows as List)
        .map((e) => MatchPredictionEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    entries.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return entries;
  }

  Future<List<PredictionHistoryEntry>> fetchPredictionHistory(
    String predictionId,
  ) async {
    final rows = await _client
        .from('prediction_history')
        .select()
        .eq('prediction_id', predictionId)
        .order('changed_at', ascending: false);

    return (rows as List)
        .map((e) => PredictionHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, List<PredictionHistoryEntry>>> fetchMatchHistoryMap(
    String matchId,
  ) async {
    final rows = await _client
        .from('prediction_history')
        .select()
        .eq('match_id', matchId)
        .order('changed_at', ascending: false);

    final map = <String, List<PredictionHistoryEntry>>{};
    for (final row in rows as List) {
      final entry = PredictionHistoryEntry.fromJson(row as Map<String, dynamic>);
      map.putIfAbsent(entry.predictionId, () => []).add(entry);
    }
    return map;
  }

  // ── Stats ──────────────────────────────────────────────────
  /// My predictions joined with their match, for the personal stats page.
  Future<List<Map<String, dynamic>>> fetchMyPredictionsWithMatches(
    String userId,
  ) async {
    final rows = await _client
        .from('predictions')
        .select('*, matches(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ── Admin: manage matches ──────────────────────────────────
  Future<List<Match>> fetchAllMatches() async {
    final rows = await _client
        .from('matches')
        .select()
        .order('kickoff_at', ascending: true);
    return (rows as List)
        .map((e) => Match.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createMatch({
    required String homeTeam,
    required String homeTeamCode,
    required String awayTeam,
    required String awayTeamCode,
    required DateTime kickoffAt,
    String? homeTeamEn,
    String? awayTeamEn,
    String? externalRef,
  }) async {
    await _client.from('matches').insert({
      'home_team': homeTeam,
      'away_team': awayTeam,
      'home_team_code': homeTeamCode,
      'away_team_code': awayTeamCode,
      'home_team_en': homeTeamEn,
      'away_team_en': awayTeamEn,
      'kickoff_at': kickoffAt.toUtc().toIso8601String(),
      'status': 'scheduled',
      if (externalRef != null && externalRef.isNotEmpty)
        'external_ref': externalRef,
    });
  }

  /// Set the final result; the DB trigger awards points automatically.
  Future<void> setMatchResult({
    required String matchId,
    required int homeScore,
    required int awayScore,
    bool finished = true,
  }) async {
    await _client.from('matches').update({
      'home_score': homeScore,
      'away_score': awayScore,
      'status': finished ? 'finished' : 'live',
    }).eq('id', matchId);
  }

  /// Undo a result — match returns to scheduled and points are cleared (migration 005).
  Future<void> resetMatchToScheduled(String matchId) async {
    await _client.from('matches').update({
      'home_score': null,
      'away_score': null,
      'status': 'scheduled',
    }).eq('id', matchId);
  }

  Future<void> rescheduleMatch({
    required String matchId,
    required DateTime kickoffAt,
  }) async {
    await _client
        .from('matches')
        .update({'kickoff_at': kickoffAt.toUtc().toIso8601String()})
        .eq('id', matchId);
  }

  Future<void> deleteMatch(String matchId) async {
    await _client.from('matches').delete().eq('id', matchId);
  }

  RealtimeChannel subscribeToMatches(void Function() onChange) {
    return _client
        .channel('matches-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matches',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  RealtimeChannel subscribeToPredictions(void Function() onChange) {
    return _client
        .channel('predictions-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'predictions',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}

class LeaderboardService {
  LeaderboardService(this._client);

  final SupabaseClient _client;

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    final rows = await _client
        .from('leaderboard')
        .select()
        .order('total_points', ascending: false);

    return (rows as List)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  RealtimeChannel subscribe(void Function() onChange) {
    return _client
        .channel('leaderboard-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'predictions',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}

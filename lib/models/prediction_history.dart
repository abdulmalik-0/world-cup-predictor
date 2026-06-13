class PredictionHistoryEntry {
  const PredictionHistoryEntry({
    required this.id,
    required this.predictionId,
    required this.userId,
    required this.matchId,
    required this.oldHomeScore,
    required this.oldAwayScore,
    required this.newHomeScore,
    required this.newAwayScore,
    required this.changedAt,
  });

  final String id;
  final String predictionId;
  final String userId;
  final String matchId;
  final int oldHomeScore;
  final int oldAwayScore;
  final int newHomeScore;
  final int newAwayScore;
  final DateTime changedAt;

  factory PredictionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PredictionHistoryEntry(
      id: json['id'] as String,
      predictionId: json['prediction_id'] as String,
      userId: json['user_id'] as String,
      matchId: json['match_id'] as String,
      oldHomeScore: json['old_home_score'] as int,
      oldAwayScore: json['old_away_score'] as int,
      newHomeScore: json['new_home_score'] as int,
      newAwayScore: json['new_away_score'] as int,
      changedAt: DateTime.parse(json['changed_at'] as String).toLocal(),
    );
  }

  String get changeSummary =>
      '$oldHomeScore-$oldAwayScore ← $newHomeScore-$newAwayScore';
}

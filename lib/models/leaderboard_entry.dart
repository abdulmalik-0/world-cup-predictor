class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.fullName,
    required this.department,
    this.avatarUrl,
    required this.totalPoints,
    required this.matchesScored,
    required this.predictionsMade,
    required this.finishedPredictions,
    required this.correctPredictions,
    required this.exactPredictions,
  });

  final String userId;
  final String fullName;
  final String department;
  final String? avatarUrl;
  final int totalPoints;
  final int matchesScored;
  final int predictionsMade;
  final int finishedPredictions;
  final int correctPredictions;
  final int exactPredictions;

  /// Correct winner/draw among finished matches (0–100).
  int get correctPercent => finishedPredictions == 0
      ? 0
      : ((correctPredictions / finishedPredictions) * 100).round();

  /// Exact score among finished matches (0–100).
  int get exactPercent => finishedPredictions == 0
      ? 0
      : ((exactPredictions / finishedPredictions) * 100).round();

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      department: json['department'] as String,
      avatarUrl: json['avatar_url'] as String?,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      matchesScored: (json['matches_scored'] as num?)?.toInt() ?? 0,
      predictionsMade: (json['predictions_made'] as num?)?.toInt() ?? 0,
      finishedPredictions:
          (json['finished_predictions'] as num?)?.toInt() ?? 0,
      correctPredictions: (json['correct_predictions'] as num?)?.toInt() ?? 0,
      exactPredictions: (json['exact_predictions'] as num?)?.toInt() ?? 0,
    );
  }
}

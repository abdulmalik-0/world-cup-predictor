class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.fullName,
    required this.department,
    this.avatarUrl,
    required this.totalPoints,
    required this.matchesScored,
    required this.predictionsMade,
  });

  final String userId;
  final String fullName;
  final String department;
  final String? avatarUrl;
  final int totalPoints;
  final int matchesScored;
  final int predictionsMade;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      department: json['department'] as String,
      avatarUrl: json['avatar_url'] as String?,
      totalPoints: (json['total_points'] as num).toInt(),
      matchesScored: (json['matches_scored'] as num).toInt(),
      predictionsMade: (json['predictions_made'] as num).toInt(),
    );
  }
}

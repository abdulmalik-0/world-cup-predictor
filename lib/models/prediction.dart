class Prediction {
  const Prediction({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.homeScore,
    required this.awayScore,
    this.pointsEarned,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String matchId;
  final int homeScore;
  final int awayScore;
  final int? pointsEarned;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      matchId: json['match_id'] as String,
      homeScore: json['home_score'] as int,
      awayScore: json['away_score'] as int,
      pointsEarned: json['points_earned'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertJson({
    required String userId,
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) =>
      {
        'user_id': userId,
        'match_id': matchId,
        'home_score': homeScore,
        'away_score': awayScore,
      };

  Map<String, dynamic> toUpdateJson({
    required int homeScore,
    required int awayScore,
  }) =>
      {
        'home_score': homeScore,
        'away_score': awayScore,
      };
}

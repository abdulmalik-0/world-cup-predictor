enum MatchStatus { scheduled, live, finished, cancelled }

class Match {
  const Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamCode,
    required this.awayTeamCode,
    required this.kickoffAt,
    this.homeScore,
    this.awayScore,
    required this.isArabTeamMatch,
    required this.status,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamCode;
  final String awayTeamCode;
  final DateTime kickoffAt;
  final int? homeScore;
  final int? awayScore;
  final bool isArabTeamMatch;
  final MatchStatus status;

  bool get isFinished => status == MatchStatus.finished;

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      homeTeam: json['home_team'] as String,
      awayTeam: json['away_team'] as String,
      homeTeamCode: json['home_team_code'] as String,
      awayTeamCode: json['away_team_code'] as String,
      kickoffAt: DateTime.parse(json['kickoff_at'] as String).toLocal(),
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      isArabTeamMatch: json['is_arab_team_match'] as bool? ?? false,
      status: MatchStatus.values.byName(json['status'] as String),
    );
  }
}

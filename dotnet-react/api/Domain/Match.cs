using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EnterGame.Api.Domain;

public enum MatchStatus { Scheduled, Live, Finished, Cancelled }

[Table("matches")]
public class Match
{
    [Column("id")]                public Guid Id { get; set; }
    [Column("home_team")]         public string HomeTeam { get; set; } = "";
    [Column("home_team_en")]      public string? HomeTeamEn { get; set; }
    [Column("away_team")]         public string AwayTeam { get; set; } = "";
    [Column("away_team_en")]      public string? AwayTeamEn { get; set; }
    [Column("home_team_code")]    public string HomeTeamCode { get; set; } = "";
    [Column("away_team_code")]    public string AwayTeamCode { get; set; } = "";
    [Column("kickoff_at")]        public DateTime KickoffAt { get; set; }
    [Column("home_score")]        public int? HomeScore { get; set; }
    [Column("away_score")]        public int? AwayScore { get; set; }
    [Column("is_arab_team_match")] public bool IsArabTeamMatch { get; set; }
    [Column("status")]            public string Status { get; set; } = "scheduled";
    [Column("external_ref")]      public string? ExternalRef { get; set; }
}

[Table("predictions")]
public class Prediction
{
    [Column("id")]            public Guid Id { get; set; }
    [Column("user_id")]       public Guid UserId { get; set; }
    [Column("match_id")]      public Guid MatchId { get; set; }
    [Column("home_score")]    public int HomeScore { get; set; }
    [Column("away_score")]    public int AwayScore { get; set; }
    [Column("points_earned")] public int? PointsEarned { get; set; }
    [Column("created_at")]    public DateTime CreatedAt { get; set; }
    [Column("updated_at")]    public DateTime UpdatedAt { get; set; }
}

[Table("profiles")]
public class Profile
{
    [Column("id")]         public Guid Id { get; set; }
    [Column("full_name")]  public string FullName { get; set; } = "";
    [Column("department")] public string Department { get; set; } = "";
    [Column("is_admin")]   public bool IsAdmin { get; set; }
}

/// Read-only projection over the public.leaderboard view (keyless).
public class LeaderboardRow
{
    [Column("user_id")]              public Guid UserId { get; set; }
    [Column("full_name")]            public string FullName { get; set; } = "";
    [Column("department")]           public string Department { get; set; } = "";
    [Column("total_points")]         public int TotalPoints { get; set; }
    [Column("predictions_made")]     public long PredictionsMade { get; set; }
    [Column("finished_predictions")] public long FinishedPredictions { get; set; }
    [Column("correct_predictions")]  public long CorrectPredictions { get; set; }
    [Column("exact_predictions")]    public long ExactPredictions { get; set; }
}

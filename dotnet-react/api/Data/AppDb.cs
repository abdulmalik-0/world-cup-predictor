using EnterGame.Api.Domain;
using Microsoft.EntityFrameworkCore;

namespace EnterGame.Api.Data;

public class AppDb(DbContextOptions<AppDb> opts) : DbContext(opts)
{
    public DbSet<Match> Matches => Set<Match>();
    public DbSet<Prediction> Predictions => Set<Prediction>();
    public DbSet<Profile> Profiles => Set<Profile>();
    public DbSet<LeaderboardRow> Leaderboard => Set<LeaderboardRow>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.HasDefaultSchema("public");
        b.Entity<Match>().Property(m => m.Id).HasDefaultValueSql("gen_random_uuid()");
        b.Entity<Prediction>().HasIndex(p => new { p.UserId, p.MatchId }).IsUnique();
        b.Entity<LeaderboardRow>().HasNoKey().ToView("leaderboard", "public");
    }
}

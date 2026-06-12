using System.Security.Claims;
using System.Text;
using EnterGame.Api.Data;
using EnterGame.Api.Domain;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// ── DB ────────────────────────────────────────────────────────────────────
var pgConn = builder.Configuration.GetConnectionString("Postgres")
             ?? Environment.GetEnvironmentVariable("POSTGRES_CONNECTION")
             ?? throw new InvalidOperationException(
                 "Set ConnectionStrings:Postgres or POSTGRES_CONNECTION.");
builder.Services.AddDbContext<AppDb>(o => o.UseNpgsql(pgConn));

// ── Auth (JWT) ────────────────────────────────────────────────────────────
var jwtKey = builder.Configuration["Jwt:Key"]
             ?? Environment.GetEnvironmentVariable("JWT_KEY")
             ?? "dev-only-key-please-rotate-in-production-1234567890";
var jwtBytes = Encoding.UTF8.GetBytes(jwtKey);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.TokenValidationParameters = new()
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(jwtBytes),
            ValidateIssuer = false,
            ValidateAudience = false,
            ClockSkew = TimeSpan.FromMinutes(1),
        };
    });
builder.Services.AddAuthorization();

// ── CORS — allow any localhost/127.0.0.1 origin (dev convenience) ──────────
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p
    .SetIsOriginAllowed(origin =>
    {
        if (!Uri.TryCreate(origin, UriKind.Absolute, out var u)) return false;
        return u.Host is "localhost" or "127.0.0.1";
    })
    .AllowAnyHeader().AllowAnyMethod()));

// ── ESPN sync service (background) ────────────────────────────────────────
builder.Services.AddHostedService<EnterGame.Api.Services.EspnSyncWorker>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
if (app.Environment.IsDevelopment()) { app.UseSwagger(); app.UseSwaggerUI(); }

// ── Endpoints ─────────────────────────────────────────────────────────────
var api = app.MapGroup("/api");

// Auth — sign in / sign up issue a JWT. (Profiles row mirrors Supabase shape.)
api.MapPost("/auth/signup", async (SignUpDto dto, AppDb db) =>
{
    if (await db.Profiles.AnyAsync(p => p.FullName == dto.FullName))
        return Results.Conflict(new { error = "name_taken" });
    var p = new Profile { Id = Guid.NewGuid(), FullName = dto.FullName, Department = dto.Department };
    db.Profiles.Add(p);
    await db.SaveChangesAsync();
    return Results.Ok(Tokens.Issue(p, jwtBytes));
});

api.MapPost("/auth/signin", async (SignInDto dto, AppDb db) =>
{
    // NOTE: In production hash + verify passwords (BCrypt is already referenced).
    var p = await db.Profiles.FirstOrDefaultAsync(x => x.FullName == dto.FullName);
    if (p == null) return Results.Unauthorized();
    return Results.Ok(Tokens.Issue(p, jwtBytes));
});

// Matches
api.MapGet("/matches", async (AppDb db) =>
    await db.Matches.OrderBy(m => m.KickoffAt).ToListAsync());

api.MapGet("/matches/upcoming", async (AppDb db) =>
    await db.Matches
        .Where(m => m.Status == "scheduled" || m.Status == "live")
        .OrderBy(m => m.KickoffAt).ToListAsync());

// Predictions
api.MapGet("/predictions/mine", [Authorize] async (ClaimsPrincipal user, AppDb db) =>
{
    var uid = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
    return await db.Predictions.Where(p => p.UserId == uid).ToListAsync();
}).RequireAuthorization();

api.MapPut("/predictions/{matchId:guid}",
    [Authorize] async (Guid matchId, PickDto dto, ClaimsPrincipal user, AppDb db) =>
{
    var uid = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
    var match = await db.Matches.FindAsync(matchId);
    if (match == null) return Results.NotFound();

    // Lock window: 1 hour before kickoff.
    if (DateTime.UtcNow >= match.KickoffAt.AddHours(-1))
        return Results.BadRequest(new { error = "window_closed" });

    var pick = await db.Predictions.FirstOrDefaultAsync(p => p.UserId == uid && p.MatchId == matchId);
    if (pick == null)
    {
        pick = new Prediction { Id = Guid.NewGuid(), UserId = uid, MatchId = matchId };
        db.Predictions.Add(pick);
    }
    pick.HomeScore = dto.HomeScore;
    pick.AwayScore = dto.AwayScore;
    pick.UpdatedAt = DateTime.UtcNow;
    await db.SaveChangesAsync();
    return Results.Ok(pick);
}).RequireAuthorization();

// Everyone's picks for a match — REVEALED ONLY after the window closes (1 hour
// before kickoff), so nobody can copy before voting ends. Returns { locked,
// finished, predictions }. Before lock, predictions is empty.
api.MapGet("/matches/{matchId:guid}/predictions", async (Guid matchId, AppDb db) =>
{
    var match = await db.Matches.FindAsync(matchId);
    if (match == null) return Results.NotFound();

    var locked = DateTime.UtcNow >= match.KickoffAt.AddHours(-1);
    if (!locked)
        return Results.Ok(new { locked = false, finished = false, predictions = Array.Empty<object>() });

    var predictions = await (
        from p in db.Predictions
        join pr in db.Profiles on p.UserId equals pr.Id
        where p.MatchId == matchId
        orderby (p.PointsEarned ?? -1) descending, pr.FullName
        select new
        {
            userId = p.UserId,
            fullName = pr.FullName,
            department = pr.Department,
            homeScore = p.HomeScore,
            awayScore = p.AwayScore,
            pointsEarned = p.PointsEarned,
        }).ToListAsync();

    return Results.Ok(new { locked = true, finished = match.Status == "finished", predictions });
});

// Leaderboard — the `leaderboard` view (migration 007), via EF keyless entity.
// Project to a plain shape (like /players) so serialization can't stall.
api.MapGet("/leaderboard", async (AppDb db) =>
    await db.Leaderboard
        .OrderByDescending(x => x.TotalPoints)
        .ThenByDescending(x => x.ExactPredictions)
        .ThenByDescending(x => x.CorrectPredictions)
        .Select(x => new
        {
            userId = x.UserId,
            fullName = x.FullName,
            department = x.Department,
            totalPoints = x.TotalPoints,
            predictionsMade = x.PredictionsMade,
            finishedPredictions = x.FinishedPredictions,
            correctPredictions = x.CorrectPredictions,
            exactPredictions = x.ExactPredictions,
        })
        .ToListAsync());

// A single player's stats (by id). Used by the My Stats page.
api.MapGet("/leaderboard/{userId:guid}", async (Guid userId, AppDb db) =>
{
    var row = await db.Leaderboard
        .Where(x => x.UserId == userId)
        .Select(x => new
        {
            userId = x.UserId,
            fullName = x.FullName,
            department = x.Department,
            totalPoints = x.TotalPoints,
            predictionsMade = x.PredictionsMade,
            finishedPredictions = x.FinishedPredictions,
            correctPredictions = x.CorrectPredictions,
            exactPredictions = x.ExactPredictions,
        })
        .FirstOrDefaultAsync();
    return row is null ? Results.NotFound() : Results.Ok(row);
});

// Lightweight roster so the UI can offer a "who am I" picker without a login.
api.MapGet("/players", async (AppDb db) =>
    await db.Profiles
        .OrderBy(p => p.FullName)
        .Select(p => new { id = p.Id, fullName = p.FullName, department = p.Department })
        .ToListAsync());

app.Run();

// ─── DTOs / helpers ──────────────────────────────────────────────────────
public record SignUpDto(string FullName, string Department);
public record SignInDto(string FullName);
public record PickDto(int HomeScore, int AwayScore);

public static class Tokens
{
    public static object Issue(Profile p, byte[] key)
    {
        var creds  = new SigningCredentials(new SymmetricSecurityKey(key),
                                            SecurityAlgorithms.HmacSha256);
        var claims = new[]
        {
            new System.Security.Claims.Claim(ClaimTypes.NameIdentifier, p.Id.ToString()),
            new System.Security.Claims.Claim(ClaimTypes.Name, p.FullName),
        };
        var jwt = new System.IdentityModel.Tokens.Jwt.JwtSecurityToken(
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: creds);
        return new
        {
            token   = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler().WriteToken(jwt),
            userId  = p.Id,
            fullName= p.FullName,
            isAdmin = p.IsAdmin,
        };
    }
}

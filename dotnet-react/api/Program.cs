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

// ── CORS for the React dev server ─────────────────────────────────────────
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p
    .WithOrigins("http://localhost:5173", "http://localhost:4173")
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

// Leaderboard (uses the `leaderboard` view from migration 007).
api.MapGet("/leaderboard", async (AppDb db) =>
{
    var conn = db.Database.GetDbConnection();
    await conn.OpenAsync();
    using var cmd = conn.CreateCommand();
    cmd.CommandText = "SELECT user_id, full_name, department, total_points, predictions_made, "
                    + "correct_predictions, exact_predictions FROM public.leaderboard";
    using var rdr = await cmd.ExecuteReaderAsync();
    var rows = new List<object>();
    while (await rdr.ReadAsync())
    {
        rows.Add(new {
            userId             = rdr.GetGuid(0),
            fullName           = rdr.GetString(1),
            department         = rdr.GetString(2),
            totalPoints        = rdr.GetInt32(3),
            predictionsMade    = rdr.GetInt64(4),
            correctPredictions = rdr.GetInt64(5),
            exactPredictions   = rdr.GetInt64(6),
        });
    }
    return Results.Ok(rows);
});

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

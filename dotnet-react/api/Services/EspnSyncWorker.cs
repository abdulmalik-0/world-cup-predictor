using System.Text.Json;
using EnterGame.Api.Data;
using EnterGame.Api.Domain;
using Microsoft.EntityFrameworkCore;

namespace EnterGame.Api.Services;

/// <summary>
/// Background worker that pulls World Cup 2026 results from ESPN every 10 min
/// and updates the local <c>matches</c> table. No API key needed — the public
/// ESPN scoreboard endpoint is free.
/// </summary>
public class EspnSyncWorker(IServiceProvider services, ILogger<EspnSyncWorker> log)
    : BackgroundService
{
    private static readonly HttpClient Http = new();

    /// <summary>ESPN TLA → app 2-letter team code.</summary>
    private static readonly Dictionary<string, string> Tla = new(StringComparer.OrdinalIgnoreCase)
    {
        ["MEX"]="MX",["RSA"]="ZA",["KOR"]="KR",["CZE"]="CZ",["CAN"]="CA",["USA"]="US",
        ["PAR"]="PY",["QAT"]="QA",["SUI"]="CH",["BRA"]="BR",["MAR"]="MA",["SCO"]="SF",
        ["HAI"]="HT",["AUS"]="AU",["TUR"]="TR",["GER"]="DE",["CUW"]="CW",["NED"]="NL",
        ["JPN"]="JP",["CIV"]="CI",["ECU"]="EC",["SWE"]="SE",["TUN"]="TN",["ESP"]="ES",
        ["CPV"]="CV",["BEL"]="BE",["EGY"]="EG",["URU"]="UY",["KSA"]="SA",["IRN"]="IR",
        ["NZL"]="NZ",["FRA"]="FR",["SEN"]="SN",["IRQ"]="IQ",["NOR"]="NO",["ARG"]="AR",
        ["ALG"]="DZ",["AUT"]="AT",["JOR"]="JO",["POR"]="PT",["COD"]="CD",["ENG"]="EN",
        ["CRO"]="HR",["GHA"]="GH",["PAN"]="PA",["UZB"]="UZ",["COL"]="CO",["BIH"]="BA",
    };

    protected override async Task ExecuteAsync(CancellationToken stop)
    {
        while (!stop.IsCancellationRequested)
        {
            try { await SyncOnce(stop); }
            catch (Exception ex) { log.LogError(ex, "ESPN sync failed"); }
            await Task.Delay(TimeSpan.FromMinutes(10), stop);
        }
    }

    private async Task SyncOnce(CancellationToken stop)
    {
        const string url =
            "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard?dates=20260611-20260720";

        using var res = await Http.GetAsync(url, stop);
        res.EnsureSuccessStatusCode();
        await using var stream = await res.Content.ReadAsStreamAsync(stop);
        using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: stop);

        if (!doc.RootElement.TryGetProperty("events", out var events)) return;

        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDb>();
        var pending = await db.Matches.Where(m => m.Status != "finished").ToListAsync(stop);

        int linked = 0, updated = 0;

        foreach (var ev in events.EnumerateArray())
        {
            var (homeCode, awayCode, homeScore, awayScore, status, espnId, when) = Parse(ev);
            if (homeCode == null || awayCode == null) continue;

            var local = pending.FirstOrDefault(m =>
                m.ExternalRef == espnId
                || (m.HomeTeamCode == homeCode && m.AwayTeamCode == awayCode
                    && Math.Abs((m.KickoffAt - when).TotalHours) <= 3));
            if (local == null) continue;

            if (local.ExternalRef == null) { local.ExternalRef = espnId; linked++; }
            if (homeScore.HasValue) local.HomeScore = homeScore.Value;
            if (awayScore.HasValue) local.AwayScore = awayScore.Value;
            if (status != null && local.Status != status) local.Status = status;
            updated++;
        }

        if (db.ChangeTracker.HasChanges()) await db.SaveChangesAsync(stop);
        log.LogInformation("ESPN sync: linked={Linked} updated={Updated}", linked, updated);
    }

    private static (string?, string?, int?, int?, string?, string, DateTime) Parse(JsonElement ev)
    {
        var id = ev.GetProperty("id").GetString()!;
        var when = ev.GetProperty("date").GetDateTime();
        var comp = ev.GetProperty("competitions")[0];
        string? home = null, away = null, status = null;
        int? hs = null, ws = null;

        foreach (var c in comp.GetProperty("competitors").EnumerateArray())
        {
            var tla = c.GetProperty("team").GetProperty("abbreviation").GetString();
            var code = tla != null && Tla.TryGetValue(tla, out var v) ? v : tla?[..Math.Min(2, tla.Length)];
            var score = c.TryGetProperty("score", out var s) && int.TryParse(s.GetString(), out var n) ? n : (int?)null;
            if (c.GetProperty("homeAway").GetString() == "home") { home = code; hs = score; }
            else { away = code; ws = score; }
        }

        var espnStatus = comp.GetProperty("status").GetProperty("type").GetProperty("name").GetString();
        status = espnStatus switch
        {
            "STATUS_FULL_TIME" or "STATUS_FINAL" or "STATUS_FINAL_PEN" or "STATUS_FINAL_AET" => "finished",
            "STATUS_IN_PROGRESS" or "STATUS_FIRST_HALF" or "STATUS_SECOND_HALF"
                or "STATUS_HALFTIME" or "STATUS_EXTRA_TIME" or "STATUS_SHOOTOUT" => "live",
            "STATUS_SCHEDULED" => "scheduled",
            "STATUS_POSTPONED" or "STATUS_CANCELED" or "STATUS_CANCELLED" => "cancelled",
            _ => null,
        };
        return (home, away, hs, ws, status, id, when);
    }
}

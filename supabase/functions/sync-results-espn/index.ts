// Supabase Edge Function: sync-results-espn
// ---------------------------------------------------------------------------
// Syncs FIFA World Cup 2026 match scores from ESPN's free public API.
// No API key required. One call fetches all scheduled/live/finished matches
// for the WC date range; local rows are matched by external_ref (ESPN event
// id) or by TLA team codes + kickoff time, then scores/status are updated.
//
// Endpoint:
//   https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard
//   ?dates=YYYYMMDD-YYYYMMDD
//
// Deploy:
//   supabase functions deploy sync-results-espn
//
// Invoke (manual test):
//   curl -X POST https://<project>.supabase.co/functions/v1/sync-results-espn \
//        -H "Authorization: Bearer <anon-or-service-key>"
// ---------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/** ESPN TLA → app team codes. Keys are uppercase 3-letter abbreviations. */
const TLA_TO_CODE: Record<string, string> = {
  MEX: "MX", RSA: "ZA", KOR: "KR", CZE: "CZ", CAN: "CA", USA: "US", PAR: "PY",
  QAT: "QA", SUI: "CH", BRA: "BR", MAR: "MA", SCO: "SF", HAI: "HT", AUS: "AU",
  TUR: "TR", GER: "DE", CUW: "CW", NED: "NL", JPN: "JP", CIV: "CI", ECU: "EC",
  SWE: "SE", TUN: "TN", ESP: "ES", CPV: "CV", BEL: "BE", EGY: "EG", URU: "UY",
  KSA: "SA", IRN: "IR", NZL: "NZ", FRA: "FR", SEN: "SN", IRQ: "IQ", NOR: "NO",
  ARG: "AR", ALG: "DZ", AUT: "AT", JOR: "JO", POR: "PT", COD: "CD", ENG: "EN",
  CRO: "HR", GHA: "GH", PAN: "PA", UZB: "UZ", COL: "CO", BIH: "BA",
};

function tlaToCode(tla: string | null | undefined): string | null {
  if (!tla) return null;
  const key = tla.toUpperCase();
  return TLA_TO_CODE[key] ?? key.slice(0, 2);
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Default WC 2026 window (group + knockouts). Override via env if needed.
const DATE_FROM = Deno.env.get("ESPN_DATE_FROM") ?? "20260611";
const DATE_TO   = Deno.env.get("ESPN_DATE_TO")   ?? "20260720";

/** Tolerance when matching ESPN event ↔ local match by team-pair + time. */
const KICKOFF_TOLERANCE_MS = 3 * 60 * 60 * 1000;

interface EspnCompetitor {
  team: { abbreviation?: string; displayName?: string };
  homeAway: "home" | "away";
  score?: string;
}

interface EspnEvent {
  id: string;
  date: string;
  name: string;
  competitions: Array<{
    competitors: EspnCompetitor[];
    status: { type: { name: string; completed?: boolean } };
  }>;
}

interface LocalMatch {
  id: string;
  external_ref: string | null;
  home_team_code: string;
  away_team_code: string;
  kickoff_at: string;
  status: string;
}

/** Normalise an ESPN status name to our app's enum. */
function mapEspnStatus(
  name: string,
): "scheduled" | "live" | "finished" | "cancelled" | null {
  switch (name) {
    case "STATUS_FULL_TIME":
    case "STATUS_FINAL":
    case "STATUS_FINAL_PEN":
    case "STATUS_FINAL_AET":
      return "finished";
    case "STATUS_IN_PROGRESS":
    case "STATUS_FIRST_HALF":
    case "STATUS_SECOND_HALF":
    case "STATUS_HALFTIME":
    case "STATUS_END_PERIOD":
    case "STATUS_EXTRA_TIME":
    case "STATUS_SHOOTOUT":
      return "live";
    case "STATUS_SCHEDULED":
      return "scheduled";
    case "STATUS_POSTPONED":
    case "STATUS_CANCELED":
    case "STATUS_CANCELLED":
    case "STATUS_ABANDONED":
      return "cancelled";
    default:
      return null;
  }
}

function pairKey(home: string, away: string): string {
  return `${home}|${away}`;
}

/** Extract { home, away, homeScore, awayScore } from an ESPN event. */
function extractSides(event: EspnEvent): {
  home: string | null;
  away: string | null;
  homeScore: number | null;
  awayScore: number | null;
} {
  const comp = event.competitions?.[0];
  if (!comp) return { home: null, away: null, homeScore: null, awayScore: null };

  let homeTla: string | undefined;
  let awayTla: string | undefined;
  let homeScore: number | null = null;
  let awayScore: number | null = null;

  for (const c of comp.competitors) {
    const tla = c.team?.abbreviation;
    const score = c.score != null && c.score !== "" ? Number(c.score) : null;
    if (c.homeAway === "home") {
      homeTla = tla;
      homeScore = Number.isFinite(score!) ? score : null;
    } else if (c.homeAway === "away") {
      awayTla = tla;
      awayScore = Number.isFinite(score!) ? score : null;
    }
  }

  return {
    home: tlaToCode(homeTla),
    away: tlaToCode(awayTla),
    homeScore,
    awayScore,
  };
}

async function fetchEspnEvents(): Promise<EspnEvent[]> {
  const url =
    `https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard?dates=${DATE_FROM}-${DATE_TO}`;
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`ESPN ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  return (data?.events ?? []) as EspnEvent[];
}

function findEvent(
  local: LocalMatch,
  byExternalRef: Map<string, EspnEvent>,
  events: EspnEvent[],
): EspnEvent | null {
  if (local.external_ref) {
    const hit = byExternalRef.get(local.external_ref);
    if (hit) return hit;
  }

  const want = pairKey(local.home_team_code, local.away_team_code);
  const localKickoff = new Date(local.kickoff_at).getTime();

  let best: EspnEvent | null = null;
  let bestDelta = Infinity;

  for (const ev of events) {
    const { home, away } = extractSides(ev);
    if (!home || !away) continue;
    if (pairKey(home, away) !== want) continue;
    const delta = Math.abs(new Date(ev.date).getTime() - localKickoff);
    if (delta <= KICKOFF_TOLERANCE_MS && delta < bestDelta) {
      best = ev;
      bestDelta = delta;
    }
  }
  return best;
}

Deno.serve(async () => {
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

  let events: EspnEvent[];
  try {
    events = await fetchEspnEvents();
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  // Build external_ref index.
  const byExternalRef = new Map<string, EspnEvent>();
  for (const ev of events) byExternalRef.set(ev.id, ev);

  // Pull every match that isn't already finished (we won't recompute those).
  const { data: localMatches, error } = await supabase
    .from("matches")
    .select(
      "id, external_ref, home_team_code, away_team_code, kickoff_at, status",
    )
    .neq("status", "finished");

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  let linked = 0;
  let updated = 0;
  const errors: string[] = [];

  for (const local of (localMatches ?? []) as LocalMatch[]) {
    // Skip TBD placeholders (knockout slots before draws are made).
    if (local.home_team_code === "XX" || local.away_team_code === "YY") {
      continue;
    }

    try {
      const ev = findEvent(local, byExternalRef, events);
      if (!ev) continue;

      const patch: Record<string, unknown> = {};

      if (!local.external_ref) {
        patch.external_ref = ev.id;
        linked++;
      }

      const status = mapEspnStatus(ev.competitions?.[0]?.status?.type?.name);
      const { homeScore, awayScore } = extractSides(ev);

      if (status && status !== local.status) {
        patch.status = status;
      }

      if (homeScore != null) patch.home_score = homeScore;
      if (awayScore != null) patch.away_score = awayScore;

      if (Object.keys(patch).length === 0) continue;

      const { error: upErr } = await supabase
        .from("matches")
        .update(patch)
        .eq("id", local.id);

      if (upErr) {
        errors.push(`${local.id}: ${upErr.message}`);
      } else {
        updated++;
      }
    } catch (e) {
      errors.push(`${local.id}: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  return new Response(
    JSON.stringify({
      ok: true,
      source: "ESPN",
      events: events.length,
      linked,
      updated,
      errors,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});

// Supabase Edge Function: sync-results
// ---------------------------------------------------------------------------
// Syncs FIFA World Cup matches from football-data.org (competition WC only).
// One API call fetches all WC fixtures; local rows are matched by external_ref
// or by home/away team codes + kickoff time, then scores/status are updated.
//
// Secrets (Supabase Dashboard → Edge Functions → Secrets):
//   FOOTBALL_API_KEY
//   FOOTBALL_COMPETITION_CODE=WC   (default)
//   FOOTBALL_SEASON=2026           (default)
//
// Deploy:
//   supabase functions deploy sync-results
// ---------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/** football-data.org TLA → app team codes (single file for Dashboard deploy). */
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
const API_KEY = Deno.env.get("FOOTBALL_API_KEY") ?? "";
const API_BASE = Deno.env.get("FOOTBALL_API_BASE") ??
  "https://api.football-data.org/v4";
const COMPETITION = Deno.env.get("FOOTBALL_COMPETITION_CODE") ?? "WC";
const SEASON = Deno.env.get("FOOTBALL_SEASON") ?? "2026";

const KICKOFF_TOLERANCE_MS = 3 * 60 * 60 * 1000;

interface ApiMatch {
  id: number;
  utcDate: string;
  status: string;
  homeTeam: { tla?: string };
  awayTeam: { tla?: string };
  score?: { fullTime?: { home?: number | null; away?: number | null } };
}

interface LocalMatch {
  id: string;
  external_ref: string | null;
  home_team_code: string;
  away_team_code: string;
  kickoff_at: string;
  status: string;
}

function mapApiStatus(status: string): "scheduled" | "live" | "finished" | "cancelled" | null {
  switch (status) {
    case "FINISHED":
      return "finished";
    case "IN_PLAY":
    case "PAUSED":
    case "LIVE":
      return "live";
    case "SCHEDULED":
    case "TIMED":
      return "scheduled";
    case "POSTPONED":
    case "SUSPENDED":
    case "CANCELLED":
      return "cancelled";
    default:
      return null;
  }
}

function pairKey(home: string, away: string): string {
  return `${home}|${away}`;
}

function apiPairKey(m: ApiMatch): string | null {
  const home = tlaToCode(m.homeTeam?.tla);
  const away = tlaToCode(m.awayTeam?.tla);
  if (!home || !away) return null;
  return pairKey(home, away);
}

async function fetchWorldCupMatches(): Promise<ApiMatch[]> {
  if (!API_KEY) {
    throw new Error("FOOTBALL_API_KEY is not set");
  }

  const url =
    `${API_BASE}/competitions/${COMPETITION}/matches?season=${SEASON}`;
  const res = await fetch(url, {
    headers: { "X-Auth-Token": API_KEY },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`football-data.org ${res.status}: ${body}`);
  }

  const data = await res.json();
  return (data?.matches ?? []) as ApiMatch[];
}

function findApiMatch(
  local: LocalMatch,
  byExternalRef: Map<string, ApiMatch>,
  byPairAndTime: ApiMatch[],
): ApiMatch | null {
  if (local.external_ref) {
    const hit = byExternalRef.get(local.external_ref);
    if (hit) return hit;
  }

  const localKickoff = new Date(local.kickoff_at).getTime();
  const key = pairKey(local.home_team_code, local.away_team_code);

  let best: ApiMatch | null = null;
  let bestDelta = Infinity;

  for (const api of byPairAndTime) {
    if (apiPairKey(api) !== key) continue;
    const delta = Math.abs(new Date(api.utcDate).getTime() - localKickoff);
    if (delta <= KICKOFF_TOLERANCE_MS && delta < bestDelta) {
      best = api;
      bestDelta = delta;
    }
  }

  return best;
}

Deno.serve(async () => {
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

  let apiMatches: ApiMatch[];
  try {
    apiMatches = await fetchWorldCupMatches();
  } catch (e) {
    return new Response(
      JSON.stringify({
        error: e instanceof Error ? e.message : String(e),
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const byExternalRef = new Map<string, ApiMatch>();
  for (const m of apiMatches) {
    byExternalRef.set(String(m.id), m);
  }

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
    if (local.home_team_code === "XX" || local.away_team_code === "YY") {
      continue;
    }

    try {
      const api = findApiMatch(local, byExternalRef, apiMatches);
      if (!api) continue;

      const patch: Record<string, unknown> = {};
      const ref = String(api.id);

      if (!local.external_ref || local.external_ref !== ref) {
        patch.external_ref = ref;
        linked++;
      }

      const mappedStatus = mapApiStatus(api.status);
      const ft = api.score?.fullTime ?? {};

      if (
        mappedStatus === "finished" &&
        ft.home !== null &&
        ft.home !== undefined &&
        ft.away !== null &&
        ft.away !== undefined
      ) {
        patch.home_score = ft.home;
        patch.away_score = ft.away;
        patch.status = "finished";
        updated++;
      } else if (mappedStatus === "live" && local.status !== "live") {
        patch.status = "live";
        updated++;
      } else if (mappedStatus === "cancelled" && local.status !== "cancelled") {
        patch.status = "cancelled";
        updated++;
      }

      if (Object.keys(patch).length === 0) continue;

      const { error: upErr } = await supabase
        .from("matches")
        .update(patch)
        .eq("id", local.id);

      if (upErr) {
        errors.push(`${local.id}: ${upErr.message}`);
      }
    } catch (e) {
      errors.push(`${local.id}: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  return new Response(
    JSON.stringify({
      competition: COMPETITION,
      season: SEASON,
      apiMatches: apiMatches.length,
      checked: localMatches?.length ?? 0,
      linked,
      updated,
      errors,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});

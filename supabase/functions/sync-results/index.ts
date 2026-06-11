// Supabase Edge Function: sync-results  (ESPN source — no API key needed)
// ---------------------------------------------------------------------------
// Syncs FIFA World Cup 2026 results from ESPN's public scoreboard.
// One call fetches every WC fixture; local rows are matched by TEAM-CODE PAIR
// (the app schedule uses real fixtures but placeholder kickoff times, so we do
// NOT match on time). For each linked row we also correct kickoff_at to the
// real time, then write scores/status when the match goes live/final.
//
// Scores are assigned per TEAM (not per home/away slot), so a reversed
// home/away in the source still lands on the right side locally.
//
// No secrets required. Deploy:  supabase functions deploy sync-results
// ---------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/** ESPN 3-letter abbreviation -> app 2-letter team code. */
const ABBR_TO_CODE: Record<string, string> = {
  MEX: "MX", RSA: "ZA", KOR: "KR", CZE: "CZ", CAN: "CA", USA: "US", PAR: "PY",
  QAT: "QA", SUI: "CH", BRA: "BR", MAR: "MA", SCO: "SF", HAI: "HT", AUS: "AU",
  TUR: "TR", GER: "DE", CUW: "CW", NED: "NL", JPN: "JP", CIV: "CI", ECU: "EC",
  SWE: "SE", TUN: "TN", ESP: "ES", CPV: "CV", BEL: "BE", EGY: "EG", URU: "UY",
  KSA: "SA", IRN: "IR", NZL: "NZ", FRA: "FR", SEN: "SN", IRQ: "IQ", NOR: "NO",
  ARG: "AR", ALG: "DZ", AUT: "AT", JOR: "JO", POR: "PT", COD: "CD", ENG: "EN",
  CRO: "HR", GHA: "GH", PAN: "PA", UZB: "UZ", COL: "CO", BIH: "BA",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ESPN_BASE = Deno.env.get("ESPN_SCOREBOARD_URL") ??
  "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard";
// WC 2026 runs 2026-06-11 .. 2026-07-19 — one range fetch covers the tournament.
const ESPN_DATES = Deno.env.get("ESPN_DATES") ?? "20260611-20260719";

interface EspnCompetitor {
  homeAway: string;
  score: string | null;
  team: { abbreviation?: string };
}
interface EspnEvent {
  id: string;
  date: string;
  status: { type: { state: string; completed: boolean } };
  competitions: { competitors: EspnCompetitor[] }[];
}

interface LocalMatch {
  id: string;
  external_ref: string | null;
  home_team_code: string;
  away_team_code: string;
  kickoff_at: string;
  status: string;
}

function codeOf(abbr: string | undefined | null): string | null {
  if (!abbr) return null;
  return ABBR_TO_CODE[abbr.toUpperCase()] ?? null; // null => placeholder/unknown
}

function pairKey(a: string, b: string): string {
  return [a, b].sort().join("|");
}

function mapState(
  state: string,
  completed: boolean,
): "scheduled" | "live" | "finished" | null {
  if (completed || state === "post") return "finished";
  if (state === "in") return "live";
  if (state === "pre") return "scheduled";
  return null;
}

async function fetchEspnEvents(): Promise<EspnEvent[]> {
  const url = `${ESPN_BASE}?dates=${ESPN_DATES}&limit=400`;
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`ESPN ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  return (data?.events ?? []) as EspnEvent[];
}

Deno.serve(async () => {
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

  let events: EspnEvent[];
  try {
    events = await fetchEspnEvents();
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }

  // Index source events by id and by unordered team-code pair.
  const byId = new Map<string, EspnEvent>();
  const byPair = new Map<string, EspnEvent>();
  for (const ev of events) {
    byId.set(String(ev.id), ev);
    const comp = ev.competitions?.[0];
    const a = codeOf(comp?.competitors?.[0]?.team?.abbreviation);
    const b = codeOf(comp?.competitors?.[1]?.team?.abbreviation);
    if (a && b) byPair.set(pairKey(a, b), ev); // real-team fixtures only
  }

  const { data: locals, error } = await supabase
    .from("matches")
    .select(
      "id, external_ref, home_team_code, away_team_code, kickoff_at, status",
    )
    .neq("status", "finished");

  if (error) return json({ error: error.message }, 500);

  let linked = 0;
  let retimed = 0;
  let scored = 0;
  let live = 0;
  const errors: string[] = [];

  for (const m of (locals ?? []) as LocalMatch[]) {
    if (m.home_team_code === "XX" || m.away_team_code === "YY") continue; // TBD knockout

    try {
      let ev = m.external_ref ? byId.get(m.external_ref) : undefined;
      if (!ev) ev = byPair.get(pairKey(m.home_team_code, m.away_team_code));
      if (!ev) continue;

      const comp = ev.competitions[0];
      const patch: Record<string, unknown> = {};

      // Link (store ESPN id for stable future lookups).
      const ref = String(ev.id);
      if (m.external_ref !== ref) patch.external_ref = ref;

      // Correct kickoff to the real time.
      if (ev.date) {
        const real = new Date(ev.date).toISOString();
        if (new Date(m.kickoff_at).toISOString() !== real) {
          patch.kickoff_at = real;
        }
      }

      // Scores assigned per team code (handles reversed home/away).
      const find = (code: string) =>
        comp.competitors.find((c) => codeOf(c.team?.abbreviation) === code);
      const home = find(m.home_team_code);
      const away = find(m.away_team_code);
      const st = mapState(ev.status?.type?.state, ev.status?.type?.completed);

      const hasScore = (c?: EspnCompetitor) =>
        c != null && c.score != null && c.score !== "" &&
        Number.isFinite(Number(c.score));

      if (st === "finished" && hasScore(home) && hasScore(away)) {
        patch.home_score = Number(home!.score);
        patch.away_score = Number(away!.score);
        patch.status = "finished";
      } else if (st === "live" && m.status !== "live") {
        patch.status = "live";
      }

      if (Object.keys(patch).length === 0) continue;

      const { error: upErr } = await supabase
        .from("matches")
        .update(patch)
        .eq("id", m.id);
      if (upErr) {
        errors.push(`${m.id}: ${upErr.message}`);
        continue;
      }

      // Count only changes that actually persisted.
      if ("external_ref" in patch) linked++;
      if ("kickoff_at" in patch) retimed++;
      if (patch.status === "finished") scored++;
      else if (patch.status === "live") live++;
    } catch (e) {
      errors.push(`${m.id}: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  return json({
    source: "espn",
    events: events.length,
    checked: locals?.length ?? 0,
    linked,
    retimed,
    scored,
    live,
    errors,
  });
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

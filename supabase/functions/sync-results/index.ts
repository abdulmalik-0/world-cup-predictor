// Supabase Edge Function: sync-results
// ---------------------------------------------------------------------------
// Pulls final scores from a football data provider and writes them into the
// `matches` table. Setting status='finished' fires the DB trigger that awards
// points to every prediction automatically.
//
// SECURITY: this runs server-side and uses the SERVICE_ROLE key (which bypasses
// RLS). NEVER put the service_role key in the Flutter web app — only here, as a
// Supabase function secret.
//
// Mapping: each local match must have `external_ref` set to the provider's
// fixture id (you set this from the in-app Admin panel when adding a match).
//
// Default provider: football-data.org (v4). To use another API, change
// `fetchProviderResult` below.
//
// Deploy:
//   supabase functions deploy sync-results
//   supabase secrets set FOOTBALL_API_KEY=xxxxx
//   (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically)
//
// Schedule (every 10 min) with pg_cron + pg_net, or call the URL from any cron.
// ---------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const API_KEY = Deno.env.get("FOOTBALL_API_KEY") ?? "";
const API_BASE = Deno.env.get("FOOTBALL_API_BASE") ??
  "https://api.football-data.org/v4";

interface ProviderResult {
  finished: boolean;
  homeScore: number | null;
  awayScore: number | null;
}

/// Adapt this to your provider. Returns null if the fixture can't be read.
async function fetchProviderResult(
  externalRef: string,
): Promise<ProviderResult | null> {
  const res = await fetch(`${API_BASE}/matches/${externalRef}`, {
    headers: { "X-Auth-Token": API_KEY },
  });
  if (!res.ok) return null;

  const data = await res.json();
  const ft = data?.score?.fullTime ?? {};
  return {
    finished: data?.status === "FINISHED",
    homeScore: ft.home ?? null,
    awayScore: ft.away ?? null,
  };
}

Deno.serve(async () => {
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

  // Only matches that are mapped and not finished yet.
  const { data: matches, error } = await supabase
    .from("matches")
    .select("id, external_ref, status")
    .not("external_ref", "is", null)
    .neq("status", "finished");

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  let updated = 0;
  const errors: string[] = [];

  for (const m of matches ?? []) {
    try {
      const result = await fetchProviderResult(m.external_ref as string);
      if (
        result?.finished &&
        result.homeScore !== null &&
        result.awayScore !== null
      ) {
        const { error: upErr } = await supabase
          .from("matches")
          .update({
            home_score: result.homeScore,
            away_score: result.awayScore,
            status: "finished",
          })
          .eq("id", m.id);
        if (upErr) {
          errors.push(`${m.id}: ${upErr.message}`);
        } else {
          updated++;
        }
      }
    } catch (e) {
      errors.push(`${m.id}: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  return new Response(
    JSON.stringify({ checked: matches?.length ?? 0, updated, errors }),
    { headers: { "Content-Type": "application/json" } },
  );
});

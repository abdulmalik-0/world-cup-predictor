import { useQuery } from '@tanstack/react-query';
import { matchesApi } from '../api/matches';
import { MatchCard } from '../components/MatchCard';

export function Dashboard() {
  const matches = useQuery({ queryKey: ['matches'], queryFn: matchesApi.upcoming });
  const picks   = useQuery({ queryKey: ['picks'],    queryFn: matchesApi.myPicks });

  const byMatch = new Map((picks.data ?? []).map(p => [p.matchId, p]));

  return (
    <main className="pt-[66px]">
      {/* Top spacer is the size of the hero — the fixed MorphingHero is
          visible underneath it. As you scroll, this section's content rises
          over the morph. */}
      <div className="h-[100svh]" aria-hidden />

      <div className="mx-auto max-w-[680px] px-4 pb-16 space-y-4 bg-ink">
        <ScoringRules />

        <header className="flex items-center gap-2 mt-4">
          <span className="text-3xl">🏆</span>
          <h2 className="text-2xl font-black">Upcoming Matches</h2>
        </header>

        {matches.isLoading && (
          <p className="opacity-60">Loading…</p>
        )}
        {matches.isError && (
          <p className="text-red-300">Could not load matches.</p>
        )}

        <div className="space-y-4">
          {(matches.data ?? []).map(m => (
            <MatchCard key={m.id} match={m} pick={byMatch.get(m.id)} />
          ))}
        </div>
      </div>
    </main>
  );
}

function ScoringRules() {
  return (
    <section className="glass rounded-2xl p-5 space-y-2">
      <h3 className="text-emerald-300 font-bold text-lg flex items-center gap-2">🏆 How points work</h3>
      <ul className="text-sm space-y-1">
        <li>✓ Exact score = <b>3 points</b></li>
        <li>👍 Correct winner or draw = <b>1 point</b></li>
        <li>✗ Wrong pick = 0</li>
      </ul>
      <hr className="border-white/15 my-2" />
      <p className="text-orange-300 font-bold">🔥 Saudi Arabia matches = double points</p>
      <p className="text-xs opacity-70">Predictions lock 1 hour before kickoff</p>
    </section>
  );
}

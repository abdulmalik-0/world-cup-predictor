import { useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import { useQuery } from '@tanstack/react-query';
import { matchesApi } from '../api/matches';
import type { Match } from '../api/types';
import { MatchCard } from '../components/MatchCard';
import { ScoringRulesCard } from '../components/ScoringRulesCard';
import { MatchCountdownBar } from '../components/MatchCountdownBar';
import { DayFilterBar, type DayOption } from '../components/DayFilterBar';
import { dayKey, dayLabel } from '../lib/time';
import { useWindowSize } from '../hooks/useWindowSize';

const NAV_H = 66;

export function Dashboard() {
  const [selectedDay, setSelectedDay] = useState<string | null>(null);

  const matchesQ = useQuery({ queryKey: ['matches'], queryFn: matchesApi.upcoming });
  const picksQ = useQuery({ queryKey: ['picks'], queryFn: matchesApi.myPicks, retry: false });

  const matches = useMemo(
    () => [...(matchesQ.data ?? [])].sort((a, b) => +new Date(a.kickoffAt) - +new Date(b.kickoffAt)),
    [matchesQ.data],
  );
  const pickByMatch = useMemo(
    () => new Map((picksQ.data ?? []).map((p) => [p.matchId, p])),
    [picksQ.data],
  );

  const days: DayOption[] = useMemo(() => {
    const seen = new Map<string, string>();
    for (const m of matches) if (!seen.has(dayKey(m.kickoffAt))) seen.set(dayKey(m.kickoffAt), dayLabel(m.kickoffAt));
    return [...seen].map(([key, label]) => ({ key, label }));
  }, [matches]);

  const nextMatch = matches.find((m) => m.status === 'scheduled') ?? matches[0];
  const filtered = selectedDay ? matches.filter((m) => dayKey(m.kickoffAt) === selectedDay) : matches;

  // Spacer = morph distance, so content rises into place as the clip lands.
  const { h: vh } = useWindowSize();
  const morph = Math.min(Math.max((vh - NAV_H) * 0.82, 320), 760);

  return (
    <main>
      {/* Hero spacer — transparent so the fixed WE-ARE-26 background and the
          morphing "26" clip show through. Content rises over it on scroll. */}
      <div style={{ height: morph }} aria-hidden />

      <div className="mx-auto w-full max-w-[680px] px-4 pb-20 space-y-[18px]" style={{ paddingTop: 8 }}>
        {nextMatch && (
          <MatchCountdownBar
            kickoffIso={nextMatch.kickoffAt}
            title={`${nextMatch.homeTeamEn ?? nextMatch.homeTeam}  ×  ${nextMatch.awayTeamEn ?? nextMatch.awayTeam}`}
          />
        )}

        <ScoringRulesCard />

        <motion.h2
          initial={{ opacity: 0, x: 16 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.4, ease: 'easeOut' }}
          className="flex items-center gap-2 text-2xl font-extrabold"
        >
          <motion.span
            animate={{ scale: [1, 1.18, 1], rotate: [-2, 2, -2] }}
            transition={{ duration: 0.9, repeat: Infinity, ease: 'easeInOut' }}
          >
            🏆
          </motion.span>
          Upcoming Matches
        </motion.h2>
        <p className="text-[13px] text-white/55 -mt-2">
          Pick a day to filter matches, or keep “All days”.
        </p>

        <DayFilterBar days={days} selectedKey={selectedDay} onSelect={setSelectedDay} />

        {matchesQ.isLoading && <p className="text-white/60">Loading…</p>}
        {matchesQ.isError && <p className="text-red-300">Could not load matches.</p>}

        <MatchList matches={filtered} showHeaders={selectedDay === null} pickByMatch={pickByMatch} />
      </div>
    </main>
  );
}

function MatchList({
  matches, showHeaders, pickByMatch,
}: {
  matches: Match[];
  showHeaders: boolean;
  pickByMatch: Map<string, { id: string; matchId: string; homeScore: number; awayScore: number; pointsEarned: number | null; userId: string }>;
}) {
  let lastDay = '';
  return (
    <div>
      {matches.map((m) => {
        const k = dayKey(m.kickoffAt);
        const header = showHeaders && k !== lastDay ? dayLabel(m.kickoffAt) : null;
        lastDay = k;
        return (
          <div key={m.id}>
            {header && (
              <div className="flex items-center gap-2 mt-4 mb-2">
                <span className="h-4 w-1 rounded bg-[#E9B84A]" />
                <span className="text-[13px] font-bold text-white/80">{header}</span>
              </div>
            )}
            <MatchCard match={m} pick={pickByMatch.get(m.id)} />
          </div>
        );
      })}
    </div>
  );
}

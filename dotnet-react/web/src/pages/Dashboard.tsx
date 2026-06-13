import { useEffect, useMemo, useState } from 'react';
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
import { useReducedMotion } from '../hooks/useReducedMotion';
import { mobileHeroHeight } from '../components/MobileHero';
import { myPicks } from '../api/predictions';
import { C } from '../lib/theme';
import { t, getLang } from '../i18n';

const NAV_H = 66;
const PAGE = 10; // matches shown initially / per "Load more"

export function Dashboard() {
  const [selectedDay, setSelectedDay] = useState<string | null>(null);
  const [visible, setVisible] = useState(PAGE);
  const still = useReducedMotion();

  const matchesQ = useQuery({ queryKey: ['matches'], queryFn: matchesApi.upcoming });
  const picksQ = useQuery({ queryKey: ['picks'], queryFn: myPicks, retry: false });

  const matches = useMemo(
    () => [...(matchesQ.data ?? [])].sort((a, b) => +new Date(a.kickoffAt) - +new Date(b.kickoffAt)),
    [matchesQ.data],
  );
  const pickByMatch = useMemo(
    () => new Map((picksQ.data ?? []).map((p) => [p.matchId, p])),
    [picksQ.data],
  );

  const loc = getLang() === 'ar' ? 'ar' : 'en';
  // Team names stay English regardless of UI language (only labels translate).
  const teamName = (en: string | null, arName: string) => en ?? arName;

  const days: DayOption[] = useMemo(() => {
    const seen = new Map<string, string>();
    for (const m of matches) if (!seen.has(dayKey(m.kickoffAt))) seen.set(dayKey(m.kickoffAt), dayLabel(m.kickoffAt, loc));
    return [...seen].map(([key, label]) => ({ key, label }));
  }, [matches, loc]);

  const nextMatch = matches.find((m) => m.status === 'scheduled') ?? matches[0];
  const filtered = selectedDay ? matches.filter((m) => dayKey(m.kickoffAt) === selectedDay) : matches;

  // Lazy load: only render the first `visible` matches; reset when the filter
  // changes. Keeps the initial DOM small (fewer cards = fewer timers/paints).
  useEffect(() => { setVisible(PAGE); }, [selectedDay]);
  const shown = filtered.slice(0, visible);
  const hasMore = filtered.length > visible;

  // Spacer = hero area, so content rises into place over it on scroll.
  const { w: vw, h: vh } = useWindowSize();
  const isMobile = vw < 768;
  // Mobile: clear the navbar + the PINNED video hero (content then scrolls over
  // it). Desktop: tall spacer = morph distance (unchanged). Desktop reduced-
  // motion: just clear the navbar (unchanged).
  const morph = isMobile
    ? NAV_H + mobileHeroHeight(vh)
    : still
    ? NAV_H + 16
    : Math.min(Math.max((vh - NAV_H) * 0.82, 320), 760);

  return (
    <main>
      {/* Hero spacer — transparent so the fixed hero shows through.
          Content rises over it on scroll. */}
      <div style={{ height: morph }} aria-hidden />

      <div
        className="mx-auto w-full max-w-[680px] px-4 pb-20 space-y-[18px]"
        // Mobile: opaque + above the pinned hero, so content scrolls OVER the
        // fixed video. Desktop: untouched (no inline background / z-index).
        style={isMobile
          ? { paddingTop: 8, position: 'relative', zIndex: 2, background: '#050505' }
          : { paddingTop: 8 }}
      >
        {nextMatch && (
          <MatchCountdownBar
            kickoffIso={nextMatch.kickoffAt}
            title={`${teamName(nextMatch.homeTeamEn, nextMatch.homeTeam)}  ×  ${teamName(nextMatch.awayTeamEn, nextMatch.awayTeam)}`}
          />
        )}

        <ScoringRulesCard />

        <h2 className="flex items-center gap-2 text-2xl font-extrabold">
          <motion.span
            animate={still ? undefined : { scale: [1, 1.18, 1], rotate: [-2, 2, -2] }}
            transition={{ duration: 0.9, repeat: Infinity, ease: 'easeInOut' }}
          >
            🏆
          </motion.span>
          {t('upcomingMatches')}
        </h2>
        <p className="text-[13px] text-white/55 -mt-2">{t('pickDayHint')}</p>

        <DayFilterBar days={days} selectedKey={selectedDay} allDaysLabel={t('allDays')} onSelect={setSelectedDay} />

        {matchesQ.isLoading && <p className="text-white/60">{t('loading')}</p>}
        {matchesQ.isError && <p className="text-red-300">{t('couldNotLoad')}</p>}

        <MatchList matches={shown} showHeaders={selectedDay === null} loc={loc} pickByMatch={pickByMatch} />

        {hasMore && (
          <button
            onClick={() => setVisible((v) => v + PAGE)}
            className="w-full py-3 rounded-xl font-bold border transition hover:bg-white/5"
            style={{ borderColor: C.pitchGreen, color: C.pitchGreen }}
          >
            {t('loadMore')} ({filtered.length - visible})
          </button>
        )}
      </div>
    </main>
  );
}

function MatchList({
  matches, showHeaders, loc, pickByMatch,
}: {
  matches: Match[];
  showHeaders: boolean;
  loc: string;
  pickByMatch: Map<string, { id: string; matchId: string; homeScore: number; awayScore: number; pointsEarned: number | null; userId: string }>;
}) {
  let lastDay = '';
  return (
    <div>
      {matches.map((m) => {
        const k = dayKey(m.kickoffAt);
        const header = showHeaders && k !== lastDay ? dayLabel(m.kickoffAt, loc) : null;
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

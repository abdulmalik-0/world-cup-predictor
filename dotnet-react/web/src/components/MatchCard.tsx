import { useState } from 'react';
import { motion } from 'framer-motion';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { Match, Prediction } from '../api/types';
import { matchesApi } from '../api/matches';

export function MatchCard({ match, pick }: { match: Match; pick?: Prediction }) {
  const [home, setHome] = useState(pick?.homeScore ?? 0);
  const [away, setAway] = useState(pick?.awayScore ?? 0);
  const qc = useQueryClient();

  const save = useMutation({
    mutationFn: () => matchesApi.savePick(match.id, home, away),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['picks'] }),
  });

  const isSaudi = match.homeTeamCode === 'SA' || match.awayTeamCode === 'SA';
  const dirty = home !== (pick?.homeScore ?? 0) || away !== (pick?.awayScore ?? 0);

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="glass rounded-2xl p-4 relative"
    >
      {/* Score bug */}
      <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-3 bg-black/40 rounded-xl p-3">
        <Flag code={match.homeTeamCode} />
        <div className="flex items-center gap-2 px-3 py-2 bg-emerald-900/50 rounded-md">
          <Stepper value={home} onChange={setHome} />
          <span className="text-2xl font-black opacity-50">×</span>
          <Stepper value={away} onChange={setAway} />
        </div>
        <Flag code={match.awayTeamCode} align="right" />
      </div>

      {isSaudi && (
        <span className="absolute -top-3 right-6 text-[11px] font-black px-2 py-1 rounded-md
                         bg-black border border-orange-400/60 text-orange-300 shadow-[0_0_14px_rgba(255,140,0,.55)]">
          Double points 🔥
        </span>
      )}

      <div className="mt-3 text-center text-sm">
        <span className="font-bold">{match.homeTeamEn ?? match.homeTeam}</span>
        <span className="opacity-50 px-2">×</span>
        <span className="font-bold">{match.awayTeamEn ?? match.awayTeam}</span>
      </div>
      <div className="text-center text-xs opacity-60 mt-1">
        {new Date(match.kickoffAt).toLocaleString()}
      </div>

      <button
        onClick={() => save.mutate()}
        disabled={!dirty || save.isPending}
        className="mt-4 w-full py-3 rounded-xl bg-emerald-500 text-black font-extrabold
                   disabled:opacity-40 disabled:cursor-not-allowed hover:bg-emerald-400 transition"
      >
        {save.isPending ? 'Saving…' : dirty ? 'Save pick' : 'Saved ✓'}
      </button>
    </motion.div>
  );
}

function Stepper({ value, onChange }: { value: number; onChange: (n: number) => void }) {
  return (
    <div className="flex flex-col items-center select-none">
      <button onClick={() => onChange(Math.min(30, value + 1))}
              className="text-white/40 hover:text-white">^</button>
      <div className="text-3xl font-black tabular-nums w-10 text-center">{value}</div>
      <button onClick={() => onChange(Math.max(0, value - 1))}
              className="text-white/40 hover:text-white rotate-180">^</button>
    </div>
  );
}

function Flag({ code, align = 'left' }: { code: string; align?: 'left' | 'right' }) {
  // ISO codes that flagcdn supports; map our 2-letter app codes.
  const iso = code.toLowerCase();
  return (
    <div className={`flex items-center ${align === 'right' ? 'justify-end' : ''} p-3`}>
      <img
        src={`https://flagcdn.com/w80/${iso}.png`}
        alt={code}
        className="h-8 rounded shadow-md"
        onError={(e) => ((e.target as HTMLImageElement).style.visibility = 'hidden')}
      />
    </div>
  );
}

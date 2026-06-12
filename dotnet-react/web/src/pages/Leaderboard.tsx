import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { matchesApi } from '../api/matches';
import type { LeaderboardEntry } from '../api/types';
import { C } from '../lib/theme';
import { hex } from '../components/CountdownBox';
import { t } from '../i18n';

export function Leaderboard() {
  const q = useQuery({ queryKey: ['leaderboard'], queryFn: matchesApi.leaderboard });
  const rows = q.data ?? [];

  return (
    <main className="pt-[86px] pb-20 px-4">
      <div className="mx-auto w-full max-w-[680px]">
        <header className="flex items-center gap-3 mb-1">
          <span className="text-3xl">🏆</span>
          <h1 className="text-2xl font-extrabold">{t('standingsTitle')}</h1>
        </header>
        <p className="text-[13px] text-white/55 mb-5">{t('standingsSub')}</p>

        {q.isLoading && <p className="text-white/60">{t('loading')}</p>}
        {q.isError && <p className="text-red-300">{t('couldNotLoad')}</p>}
        {!q.isLoading && rows.length === 0 && (
          <p className="text-white/60">{t('noParticipants')}</p>
        )}

        <div className="space-y-2">
          {rows.map((r, i) => (
            <Row key={r.userId} entry={r} rank={i + 1} />
          ))}
        </div>
      </div>
    </main>
  );
}

function Row({ entry, rank }: { entry: LeaderboardEntry; rank: number }) {
  const medal = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : null;
  const top3 = rank <= 3;
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, delay: Math.min(rank * 0.025, 0.4) }}
      className="glass rounded-2xl px-3 py-3 flex items-center gap-3"
      style={top3 ? { border: `1px solid ${hex(C.accentGold, 0.5)}` } : undefined}
    >
      <div
        className="w-8 h-8 rounded-full flex items-center justify-center font-black text-sm shrink-0"
        style={{
          background: top3 ? hex(C.accentGold, 0.18) : 'rgba(255,255,255,0.06)',
          color: top3 ? C.accentGold : '#fff',
        }}
      >
        {medal ?? rank}
      </div>

      <div className="flex-1 min-w-0">
        <div className="font-bold truncate">{entry.fullName}</div>
        <div className="text-[12px] text-white/50 truncate">{entry.department}</div>
      </div>

      <div className="hidden sm:flex items-center gap-4 text-center">
        <Stat label={t('correctShort')} value={entry.correctPredictions} />
        <Stat label={t('exactShort')} value={entry.exactPredictions} />
      </div>

      <div className="text-end shrink-0 min-w-[58px]">
        <div className="font-black text-lg leading-none" style={{ color: C.pitchGreen }}>
          {entry.totalPoints}
        </div>
        <div className="text-[11px] text-white/50">{t('pts')}</div>
      </div>
    </motion.div>
  );
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div>
      <div className="font-bold text-sm">{value}</div>
      <div className="text-[10px] uppercase tracking-wide text-white/45">{label}</div>
    </div>
  );
}

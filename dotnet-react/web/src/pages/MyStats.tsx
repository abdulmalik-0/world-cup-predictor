import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { matchesApi } from '../api/matches';
import type { LeaderboardEntry } from '../api/types';
import { C } from '../lib/theme';
import { hex } from '../components/CountdownBox';
import { getUserId } from '../lib/identity';
import { t } from '../i18n';

export function MyStats() {
  const userId = getUserId(); // the signed-in user

  const board = useQuery({ queryKey: ['leaderboard'], queryFn: matchesApi.leaderboard });
  const rows = board.data ?? [];

  const me = rows.find((r) => r.userId === userId) ?? null;
  const rank = me ? rows.findIndex((r) => r.userId === userId) + 1 : null;

  return (
    <main className="pt-[86px] pb-20 px-4">
      <div className="mx-auto w-full max-w-[680px]">
        <header className="flex items-center gap-3 mb-5">
          <span className="text-3xl">📊</span>
          <h1 className="text-2xl font-extrabold">{t('myStats')}</h1>
        </header>

        {!me ? (
          <p className="text-white/60">{t('loading')}</p>
        ) : (
          <StatsView me={me} rank={rank!} total={rows.length} />
        )}
      </div>
    </main>
  );
}

function StatsView({
  me, rank, total,
}: { me: LeaderboardEntry; rank: number; total: number }) {
  const accuracy = me.finishedPredictions > 0
    ? Math.round((me.correctPredictions / me.finishedPredictions) * 100)
    : 0;

  return (
    <div className="space-y-4">
      {/* Identity + rank */}
      <div className="glass rounded-2xl p-5 flex items-center gap-4">
        <div
          className="w-14 h-14 rounded-full flex items-center justify-center text-2xl font-black shrink-0"
          style={{ background: hex(C.accentGold, 0.18), color: C.accentGold }}
        >
          {rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : `#${rank}`}
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-lg font-extrabold truncate">{me.fullName}</div>
          <div className="text-[13px] text-white/55 truncate">{me.department}</div>
          <div className="text-[12px] mt-0.5" style={{ color: C.accentGold }}>
            {t('yourRank')}: {rank} / {total}
          </div>
        </div>
      </div>

      {/* Stat tiles */}
      <div className="grid grid-cols-2 gap-3">
        <Tile big value={me.totalPoints} label={t('totalPoints')} color={C.pitchGreen} delay={0} />
        <Tile value={me.predictionsMade} label={t('predictionsCount')} color="#fff" delay={0.05} />
        <Tile value={`${accuracy}%`} label={t('accuracy')} color={C.accentGold} delay={0.1} />
        <Tile value={me.exactPredictions} label={t('exactPicks')} color={C.arabBadgeOrange} delay={0.15} />
      </div>
    </div>
  );
}

function Tile({
  value, label, color, big, delay,
}: { value: string | number; label: string; color: string; big?: boolean; delay: number }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, delay }}
      className="glass rounded-2xl p-4 flex flex-col items-center justify-center text-center"
      style={big ? { border: `1px solid ${hex(color, 0.5)}` } : undefined}
    >
      <div className="font-black leading-none" style={{ color, fontSize: big ? 40 : 30 }}>
        {value}
      </div>
      <div className="text-[12px] text-white/55 mt-1.5">{label}</div>
    </motion.div>
  );
}

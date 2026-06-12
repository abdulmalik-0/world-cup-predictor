import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { matchesApi } from '../api/matches';
import type { LeaderboardEntry } from '../api/types';
import { C } from '../lib/theme';
import { hex } from '../components/CountdownBox';
import { getUserId } from '../lib/identity';
import { t } from '../i18n';

export function MyStats() {
  const myId = getUserId(); // the signed-in user
  const [selectedId, setSelectedId] = useState<string | null>(myId);

  const board = useQuery({ queryKey: ['leaderboard'], queryFn: matchesApi.leaderboard });
  const rows = board.data ?? [];

  // Anyone can be viewed — dropdown of every player, default = you.
  const players = useMemo(
    () => [...rows].sort((a, b) => a.fullName.localeCompare(b.fullName)),
    [rows],
  );
  const target = selectedId ?? myId;
  const me = rows.find((r) => r.userId === target) ?? null;
  const rank = me ? rows.findIndex((r) => r.userId === target) + 1 : null;

  return (
    <main className="pt-[86px] pb-20 px-4">
      <div className="mx-auto w-full max-w-[680px]">
        <header className="flex items-center gap-3 mb-4">
          <span className="text-3xl">📊</span>
          <h1 className="text-2xl font-extrabold">{t('myStats')}</h1>
        </header>

        {rows.length > 0 && (
          <div className="mb-4">
            <label className="block text-[12px] text-white/55 mb-1.5">{t('selectPlayer')}</label>
            <select
              value={target ?? ''}
              onChange={(e) => setSelectedId(e.target.value)}
              className="w-full rounded-xl bg-black/40 border border-white/15 px-3 py-3 text-white outline-none focus:border-emerald-400"
            >
              {players.map((p) => (
                <option key={p.userId} value={p.userId} className="bg-[#0B1118]">
                  {p.fullName}{p.userId === myId ? `  (${t('youLabel')})` : ''} — {p.department}
                </option>
              ))}
            </select>
          </div>
        )}

        {!me ? (
          <p className="text-white/60">{t('loading')}</p>
        ) : (
          <StatsView me={me} rank={rank!} total={rows.length} isMe={me.userId === myId} />
        )}
      </div>
    </main>
  );
}

function StatsView({
  me, rank, total, isMe,
}: { me: LeaderboardEntry; rank: number; total: number; isMe: boolean }) {
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
          <div className="text-lg font-extrabold truncate">
            {me.fullName}
            {isMe && <span className="ml-2 text-[11px] font-bold px-1.5 py-0.5 rounded" style={{ background: hex(C.pitchGreen, 0.2), color: C.pitchGreen }}>{t('youLabel')}</span>}
          </div>
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

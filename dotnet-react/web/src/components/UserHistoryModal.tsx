import { createPortal } from 'react-dom';
import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import type { UserPick } from '../api/types';
import { matchesApi } from '../api/matches';
import { C } from '../lib/theme';
import { flagUrl } from '../lib/teams';
import { hex } from './CountdownBox';
import { t } from '../i18n';

/** Bottom-sheet showing one player's past predictions (from the leaderboard). */
export function UserHistoryModal({
  userId, fullName, onClose,
}: { userId: string; fullName: string; onClose: () => void }) {
  const q = useQuery({
    queryKey: ['history', userId],
    queryFn: () => matchesApi.playerHistory(userId),
  });
  const rows = q.data ?? [];

  return createPortal(
    <motion.div
      className="fixed inset-0 z-[60] flex items-end sm:items-center justify-center"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
    >
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onClose} />

      <motion.div
        initial={{ y: 40, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ type: 'spring', stiffness: 320, damping: 32 }}
        className="relative w-full sm:max-w-[540px] max-h-[82vh] flex flex-col rounded-t-3xl sm:rounded-3xl
                   border border-white/15 overflow-hidden"
        style={{ background: '#0B1118' }}
      >
        <div className="pt-3 pb-1 flex justify-center">
          <div className="h-1.5 w-12 rounded-full bg-white/20" />
        </div>
        <header className="px-5 pt-1 pb-3 text-center">
          <h3 className="text-lg font-extrabold truncate">{fullName}</h3>
          <p className="text-[13px] text-white/55 mt-0.5">{t('history')}</p>
        </header>

        <div className="flex-1 overflow-y-auto px-3 pb-5">
          {q.isLoading && <p className="text-center text-white/55 py-6">{t('loading')}</p>}
          {!q.isLoading && rows.length === 0 && (
            <p className="text-center text-white/50 py-6">{t('noHistory')}</p>
          )}
          <div className="divide-y divide-white/8">
            {rows.map((r) => <HistoryRow key={r.matchId} row={r} />)}
          </div>
        </div>
      </motion.div>
    </motion.div>,
    document.body,
  );
}

function HistoryRow({ row }: { row: UserPick }) {
  const home = row.homeTeamEn ?? row.homeTeam;
  const away = row.awayTeamEn ?? row.awayTeam;
  const finished = row.status === 'finished' && row.homeScore != null;
  const exact = row.pointsEarned != null && row.pointsEarned >= 3;
  const correct = row.pointsEarned != null && row.pointsEarned > 0;

  return (
    <div className="py-2.5 px-1 flex items-center gap-3">
      {/* teams */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-1.5 text-[13px] font-semibold truncate">
          <Flag code={row.homeTeamCode} />
          <span className="truncate">{home}</span>
          <span className="opacity-40 px-0.5">×</span>
          <span className="truncate">{away}</span>
          <Flag code={row.awayTeamCode} />
        </div>
        <div className="text-[11px] text-white/45 mt-0.5" dir="ltr">
          {t('theirPick')}: <b className="text-white/75">{row.predHome}:{row.predAway}</b>
          {finished && <> · {t('finalResult')}: <b className="text-white/75">{row.homeScore}:{row.awayScore}</b></>}
        </div>
      </div>

      {/* points */}
      <div className="shrink-0 text-end min-w-[44px]">
        {finished && row.pointsEarned != null ? (
          <span
            className="inline-block px-2 py-1 rounded-lg font-black text-[13px]"
            style={{
              background: exact ? hex(C.accentGold, 0.18) : correct ? hex(C.pitchGreen, 0.16) : 'rgba(255,255,255,0.06)',
              color: exact ? C.accentGold : correct ? C.pitchGreen : 'rgba(255,255,255,0.5)',
            }}
          >
            +{row.pointsEarned}
          </span>
        ) : (
          <span className="text-[11px] text-white/35">—</span>
        )}
      </div>
    </div>
  );
}

function Flag({ code }: { code: string }) {
  const url = flagUrl(code);
  return url ? <img src={url} alt={code} className="h-4 w-6 object-cover rounded-[2px] shrink-0" /> : null;
}

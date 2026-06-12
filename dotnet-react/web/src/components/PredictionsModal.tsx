import { createPortal } from 'react-dom';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import type { Match, MatchPick } from '../api/types';
import { matchesApi } from '../api/matches';
import { C } from '../lib/theme';
import { hex } from './CountdownBox';
import { isPredictionOpen } from '../lib/time';
import { t, getLang } from '../i18n';

/**
 * Bottom-sheet modal listing everyone's picks for a match. The server only
 * returns the full list AFTER the voting window closes (1 hour before kickoff),
 * so before that we show a "hidden until close" banner. The current user (the
 * name chosen on My Stats, stored in eg.userId) is highlighted as "You".
 */
export function PredictionsModal({ match, onClose }: { match: Match; onClose: () => void }) {
  const open = isPredictionOpen(match.kickoffAt);
  const meId = localStorage.getItem('eg.userId');
  const ar = getLang() === 'ar';

  const q = useQuery({
    queryKey: ['matchPicks', match.id],
    queryFn: () => matchesApi.matchPicks(match.id),
  });

  const picks = q.data?.predictions ?? [];
  const finished = q.data?.finished ?? false;
  const home = ar ? match.homeTeam : (match.homeTeamEn ?? match.homeTeam);
  const away = ar ? match.awayTeam : (match.awayTeamEn ?? match.awayTeam);

  return createPortal(
    <AnimatePresence>
      <motion.div
        className="fixed inset-0 z-[60] flex items-end sm:items-center justify-center"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
      >
        {/* scrim */}
        <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onClose} />

        <motion.div
          initial={{ y: 40, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ type: 'spring', stiffness: 320, damping: 32 }}
          className="relative w-full sm:max-w-[520px] max-h-[82vh] flex flex-col rounded-t-3xl sm:rounded-3xl
                     border border-white/15 overflow-hidden"
          style={{ background: '#0B1118' }}
        >
          {/* grab handle */}
          <div className="pt-3 pb-1 flex justify-center">
            <div className="h-1.5 w-12 rounded-full bg-white/20" />
          </div>

          <header className="px-5 pt-1 pb-3 text-center">
            <h3 className="text-lg font-extrabold">{t('colleaguePicks')}</h3>
            <p className="text-[13px] text-white/55 mt-0.5">
              {home} <span className="opacity-50">×</span> {away}
            </p>
          </header>

          {open && (
            <div
              className="mx-4 mb-3 rounded-xl px-3 py-2.5 flex items-start gap-2 text-[12.5px]"
              style={{ background: hex(C.primaryGreen, 0.14), color: C.pitchGreen }}
            >
              <span>🔒</span>
              <span>{t('picksHidden')}</span>
            </div>
          )}

          <div className="flex-1 overflow-y-auto px-3 pb-5">
            {q.isLoading && <p className="text-center text-white/55 py-6">{t('loading')}</p>}
            {q.isError && <p className="text-center text-red-300 py-6">{t('errLoadPicks')}</p>}
            {/* Only show the "empty" note once voting is actually closed. */}
            {!q.isLoading && !q.isError && !open && picks.length === 0 && (
              <p className="text-center text-white/50 py-6">{t('noPicksYet')}</p>
            )}

            <div className="divide-y divide-white/8">
              {picks.map((p) => (
                <Row key={p.userId} pick={p} isMe={p.userId === meId} showPoints={finished} />
              ))}
            </div>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>,
    document.body,
  );
}

function Row({ pick, isMe, showPoints }: { pick: MatchPick; isMe: boolean; showPoints: boolean }) {
  const initial = pick.fullName.trim().charAt(0).toUpperCase() || '?';
  return (
    <div className="flex items-center gap-3 py-2.5 px-1">
      <div
        className="w-9 h-9 rounded-full flex items-center justify-center font-black shrink-0"
        style={{
          background: isMe ? hex(C.pitchGreen, 0.25) : 'rgba(255,255,255,0.08)',
          color: isMe ? C.pitchGreen : '#fff',
        }}
      >
        {initial}
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className={`truncate ${isMe ? 'font-extrabold' : 'font-semibold'}`}>{pick.fullName}</span>
          {isMe && (
            <span
              className="text-[10px] font-bold px-1.5 py-0.5 rounded shrink-0"
              style={{ background: hex(C.pitchGreen, 0.2), color: C.pitchGreen }}
            >
              {t('youLabel')}
            </span>
          )}
        </div>
        {pick.department && <div className="text-[12px] text-white/45 truncate">{pick.department}</div>}
      </div>

      <div className="text-end shrink-0" dir="ltr">
        <div className="font-black text-base leading-none tabular-nums">
          {pick.homeScore} : {pick.awayScore}
        </div>
        {showPoints && pick.pointsEarned != null && (
          <div className="text-[11px] font-bold mt-0.5" style={{ color: C.accentGold }}>
            +{pick.pointsEarned} {t('pts')}
          </div>
        )}
      </div>
    </div>
  );
}

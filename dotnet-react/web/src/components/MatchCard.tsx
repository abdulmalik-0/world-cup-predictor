import { useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { Match, Prediction } from '../api/types';
import { matchesApi } from '../api/matches';
import { C } from '../lib/theme';
import { flagUrl, jerseyColor, isSaudi as isSaudiCode } from '../lib/teams';
import { isPredictionOpen, untilLock, formatKickoff } from '../lib/time';
import { useNow } from '../hooks/useNow';
import { CountdownBox, hex } from './CountdownBox';
import { PredictionsModal } from './PredictionsModal';
import { t, getLang } from '../i18n';

const MAX = 30;

export function MatchCard({ match, pick }: { match: Match; pick?: Prediction }) {
  const [home, setHome] = useState(pick?.homeScore ?? 0);
  const [away, setAway] = useState(pick?.awayScore ?? 0);
  const [justSaved, setJustSaved] = useState(false);
  const [showPicks, setShowPicks] = useState(false);
  const savedTimer = useRef<number | undefined>(undefined);
  const qc = useQueryClient();
  const now = useNow();

  useEffect(() => {
    setHome(pick?.homeScore ?? 0);
    setAway(pick?.awayScore ?? 0);
  }, [pick?.id]); // eslint-disable-line react-hooks/exhaustive-deps

  const open = isPredictionOpen(match.kickoffAt, now);
  const hasPick = !!pick;
  const dirty = !pick || home !== pick.homeScore || away !== pick.awayScore;
  const saudi = isSaudiCode(match.homeTeamCode) || isSaudiCode(match.awayTeamCode);

  const save = useMutation({
    mutationFn: () => matchesApi.savePick(match.id, home, away),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['picks'] });
      setJustSaved(true);
      window.clearTimeout(savedTimer.current);
      savedTimer.current = window.setTimeout(() => setJustSaved(false), 1800);
    },
  });

  const ar = getLang() === 'ar';
  const homeName = ar ? (match.homeTeam ?? match.homeTeamEn) : (match.homeTeamEn ?? match.homeTeam);
  const awayName = ar ? (match.awayTeam ?? match.awayTeamEn) : (match.awayTeamEn ?? match.awayTeam);

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="glass rounded-[18px] px-3.5 pt-4 pb-4 mb-4"
    >
      {/* ── Broadcast score bug (always LTR: home → away) ── */}
      <div dir="ltr" className="flex flex-col items-stretch">
        <div className="relative">
          <div className="overflow-hidden rounded-2xl flex h-[70px]" style={{ background: C.codeBg }}>
            <div style={{ width: 5, background: jerseyColor(match.homeTeamCode) }} />
            <Flag code={match.homeTeamCode} />
            <ScoreCell value={home} onChange={setHome} open={open} />
            <CenterBadge />
            <ScoreCell value={away} onChange={setAway} open={open} />
            <Flag code={match.awayTeamCode} />
            <div style={{ width: 5, background: jerseyColor(match.awayTeamCode) }} />
          </div>

          {saudi && (
            <div
              className="absolute -top-4"
              style={isSaudiCode(match.homeTeamCode) ? { left: 24 } : { right: 24 }}
            >
              <DoubleBadge />
            </div>
          )}
        </div>

        <div className="-mt-px flex justify-center">
          <ClockTab kickoffIso={match.kickoffAt} open={open} now={now} />
        </div>
      </div>

      {/* ── Team names + kickoff ── */}
      <div className="text-center mt-3.5 font-bold text-[14px]">
        {homeName} <span className="opacity-50 px-1">×</span> {awayName}
      </div>
      <div className="text-center mt-0.5 text-[12px] text-white/55 flex items-center justify-center gap-1.5">
        <span>📅</span> {formatKickoff(match.kickoffAt)}
      </div>

      {/* ── See everyone's picks ── */}
      <button
        onClick={() => setShowPicks(true)}
        className="mt-3 w-full py-2.5 rounded-xl font-bold text-[14px] flex items-center justify-center gap-2
                   border transition hover:bg-white/5"
        style={{ borderColor: hex(C.pitchGreen, 0.5), color: C.pitchGreen }}
      >
        <span>👥</span> {t('picks')}
      </button>

      {showPicks && <PredictionsModal match={match} onClose={() => setShowPicks(false)} />}

      {/* ── Save / closed ── */}
      {open ? (
        <>
          <StatusLine justSaved={justSaved} hasPick={hasPick} dirty={dirty} />
          <button
            onClick={() => save.mutate()}
            disabled={!dirty || save.isPending}
            className="mt-2.5 w-full py-3 rounded-xl font-extrabold transition disabled:cursor-not-allowed"
            style={
              justSaved
                ? { background: C.pitchGreen, color: '#04130C' }
                : dirty
                ? { background: C.primaryGreen, color: '#fff' }
                : { background: 'rgba(255,255,255,0.08)', color: 'rgba(255,255,255,0.5)' }
            }
          >
            {save.isPending
              ? t('saving')
              : justSaved
              ? t('savedBang')
              : !hasPick
              ? t('savePick')
              : dirty
              ? t('updatePick')
              : t('saved')}
          </button>
        </>
      ) : (
        <ClosedSummary match={match} pick={pick} />
      )}
    </motion.div>
  );
}

function ScoreCell({ value, onChange, open }: { value: number; onChange: (n: number) => void; open: boolean }) {
  const number = (
    <motion.div
      key={value}
      initial={{ scale: 1.35 }}
      animate={{ scale: 1 }}
      transition={{ duration: 0.2, ease: 'easeOut' }}
      className="text-white font-black"
      style={{ fontSize: 30, lineHeight: 1 }}
    >
      {value}
    </motion.div>
  );
  return (
    <div className="flex flex-col items-center justify-center" style={{ width: 56, background: C.scoreBg }}>
      {open ? (
        <>
          <Chevron dir="up" onClick={value < MAX ? () => onChange(value + 1) : undefined} />
          <div className="flex-1 flex items-center justify-center">{number}</div>
          <Chevron dir="down" onClick={value > 0 ? () => onChange(value - 1) : undefined} />
        </>
      ) : (
        <div className="flex-1 flex items-center justify-center">{number}</div>
      )}
    </div>
  );
}

function Chevron({ dir, onClick }: { dir: 'up' | 'down'; onClick?: () => void }) {
  return (
    <button
      onClick={onClick}
      disabled={!onClick}
      className="h-5 w-full flex items-center justify-center"
      style={{ color: onClick ? '#fff' : 'rgba(255,255,255,0.25)' }}
    >
      <svg
        width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
        strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
        style={{ transform: dir === 'down' ? 'rotate(180deg)' : 'none' }}
      >
        <polyline points="6 15 12 9 18 15" />
      </svg>
    </button>
  );
}

function Flag({ code }: { code: string }) {
  const url = flagUrl(code);
  return (
    <div className="flex-1 flex items-center justify-center px-4 py-3" style={{ background: C.codeBg }}>
      {url ? (
        <img
          src={url}
          alt={code}
          className="max-h-full rounded-[3px] object-contain"
          style={{ maxWidth: 56 }}
          onError={(e) => ((e.target as HTMLImageElement).style.visibility = 'hidden')}
        />
      ) : (
        <span className="text-white/25">⚑</span>
      )}
    </div>
  );
}

/** Center World Cup 26 logo badge inside the score bug. */
function CenterBadge() {
  return (
    <div className="flex items-center justify-center" style={{ width: 54, background: C.codeBg }}>
      <img src="/wc26_logo.png" alt="WC26" style={{ height: 58, objectFit: 'contain' }} />
    </div>
  );
}

/** Green glassy clock tab (or red "Closed" tab) hanging below the bug. */
function ClockTab({ kickoffIso, open, now }: { kickoffIso: string; open: boolean; now: number }) {
  if (!open) {
    return (
      <div
        className="flex items-center gap-1.5 px-4 py-1.5 text-white font-black text-[15px]"
        style={{ background: '#B3261E', borderRadius: '0 0 12px 12px' }}
      >
        🔒 {t('closed')}
      </div>
    );
  }
  const time = untilLock(kickoffIso, now);
  return (
    <div
      dir="ltr"
      className="flex items-end gap-1 px-2 pt-[5px] pb-1.5"
      style={{
        borderRadius: '0 0 12px 12px',
        background: `linear-gradient(135deg, ${hex(C.blueAccent, 0.18)}, rgba(255,255,255,0.04))`,
        border: `1px solid ${hex(C.blueAccent, 0.3)}`,
        backdropFilter: 'blur(14px)',
      }}
    >
      <CountdownBox size="tab" value={time.days} label={t('days')} />
      <CountdownBox size="tab" value={time.hours} label={t('hrs')} />
      <CountdownBox size="tab" value={time.mins} label={t('min')} />
      <CountdownBox size="tab" value={time.secs} label={t('sec')} />
    </div>
  );
}

function DoubleBadge() {
  return (
    <motion.div
      animate={{ scale: [1, 1.08, 1] }}
      transition={{ duration: 0.7, repeat: Infinity, ease: 'easeInOut' }}
      className="px-2.5 py-1 rounded-[10px] font-black text-[11px] whitespace-nowrap"
      style={{
        background: '#1A1A1A',
        color: C.arabBadgeOrange,
        border: `1px solid ${hex(C.arabBadgeOrange, 0.5)}`,
        boxShadow: `0 0 14px -2px ${hex(C.arabBadgeOrange, 0.55)}`,
      }}
    >
      {t('doubleBadge')}
    </motion.div>
  );
}

function StatusLine({ justSaved, hasPick, dirty }: { justSaved: boolean; hasPick: boolean; dirty: boolean }) {
  let icon = '', text = '', color = '';
  if (justSaved) { icon = '✅'; text = t('pickSaved'); color = C.pitchGreen; }
  else if (hasPick && dirty) { icon = '✎'; text = t('unsavedChanges'); color = C.accentGold; }
  else if (hasPick && !dirty) { icon = '✔'; text = t('yourPickSaved'); color = C.pitchGreen; }
  else return <div className="h-3" />;
  return (
    <div className="flex items-center justify-center gap-1.5 mt-3 text-[12px] font-bold" style={{ color }}>
      <span>{icon}</span> {text}
    </div>
  );
}

function ClosedSummary({ match, pick }: { match: Match; pick?: Prediction }) {
  const finished = match.status === 'finished' && match.homeScore != null;
  return (
    <div className="mt-3 flex flex-col items-center gap-2 text-[14px]">
      {finished && <Chip label={t('result')} value={`${match.homeScore} : ${match.awayScore}`} color={C.accentGold} />}
      {pick ? (
        <Chip label={t('yourPick')} value={`${pick.homeScore} : ${pick.awayScore}`} color={C.pitchGreen} />
      ) : (
        <span className="text-white/55 text-[13px]">{t('noPrediction')}</span>
      )}
      {finished && pick?.pointsEarned != null && (
        <div className="mt-1 font-black text-[16px]" style={{ color: C.accentGold }}>
          +{pick.pointsEarned} {t('pts')}
        </div>
      )}
    </div>
  );
}

function Chip({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <div className="flex items-center gap-2">
      <span className="text-white/80">{label}:</span>
      <span className="px-3.5 py-1 rounded-[10px] font-black" style={{ background: hex(color, 0.16), color }}>
        {value}
      </span>
    </div>
  );
}

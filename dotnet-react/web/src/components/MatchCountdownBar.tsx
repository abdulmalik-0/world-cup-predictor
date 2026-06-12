import { motion } from 'framer-motion';
import { C } from '../lib/theme';
import { untilKickoff } from '../lib/time';
import { useNow } from '../hooks/useNow';
import { useReducedMotion } from '../hooks/useReducedMotion';
import { CountdownBox, hex } from './CountdownBox';
import { t } from '../i18n';

/** The navy "Next match" bar at the top of the dashboard list. */
export function MatchCountdownBar({ kickoffIso, title }: { kickoffIso: string; title?: string }) {
  const now = useNow();
  const time = untilKickoff(kickoffIso, now);
  const live = time.negative;
  const still = useReducedMotion();

  return (
    <motion.div
      initial={still ? false : { opacity: 0, y: 14 }}
      animate={still ? undefined : { opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: 'easeOut' }}
      className="flex items-center gap-3 px-3.5 py-3 rounded-2xl"
      style={{
        background: `linear-gradient(${C.navyTop}, ${C.navyBottom})`,
        border: `1px solid ${hex(C.blueAccent, 0.4)}`,
        boxShadow: `0 0 24px -8px ${hex(C.blueAccent, 0.15)}`,
      }}
    >
      <span style={{ fontSize: 22 }}>⚽</span>
      <div className="flex-1 min-w-0">
        <div style={{ color: C.goldLabel, fontWeight: 900, fontSize: 12, letterSpacing: 1 }}>
          {live ? t('liveNow') : t('nextMatch')}
        </div>
        {title && (
          <div className="truncate text-white" style={{ fontWeight: 700, fontSize: 14 }}>
            {title}
          </div>
        )}
      </div>
      {!live && (
        <div className="flex items-end gap-1.5" dir="ltr">
          <CountdownBox value={time.days} label={t('days')} />
          <CountdownBox value={time.hours} label={t('hours')} />
          <CountdownBox value={time.mins} label={t('minutes')} />
          <CountdownBox value={time.secs} label={t('seconds')} />
        </div>
      )}
    </motion.div>
  );
}

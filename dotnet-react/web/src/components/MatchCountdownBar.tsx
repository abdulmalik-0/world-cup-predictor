import { motion } from 'framer-motion';
import { C } from '../lib/theme';
import { untilKickoff } from '../lib/time';
import { useNow } from '../hooks/useNow';
import { CountdownBox, hex } from './CountdownBox';

/** The navy "Next match" bar at the top of the dashboard list. */
export function MatchCountdownBar({ kickoffIso, title }: { kickoffIso: string; title?: string }) {
  const now = useNow();
  const t = untilKickoff(kickoffIso, now);
  const live = t.negative;

  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: 'easeOut' }}
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
          {live ? 'Live now 🔴' : 'Next match'}
        </div>
        {title && (
          <div className="truncate text-white" style={{ fontWeight: 700, fontSize: 14 }}>
            {title}
          </div>
        )}
      </div>
      {!live && (
        <div className="flex items-end gap-1.5">
          <CountdownBox value={t.days} label="DAYS" />
          <CountdownBox value={t.hours} label="HOURS" />
          <CountdownBox value={t.mins} label="MINUTES" />
          <CountdownBox value={t.secs} label="SECONDS" />
        </div>
      )}
    </motion.div>
  );
}

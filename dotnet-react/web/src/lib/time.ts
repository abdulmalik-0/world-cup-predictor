/** Predictions lock 1 hour before kickoff (same rule as the Flutter app). */
const LOCK_MS = 60 * 60 * 1000;

export interface Parts { days: number; hours: number; mins: number; secs: number; negative: boolean; }

function split(ms: number): Parts {
  const negative = ms < 0;
  const t = Math.abs(ms);
  return {
    negative,
    days: Math.floor(t / 86_400_000),
    hours: Math.floor(t / 3_600_000) % 24,
    mins: Math.floor(t / 60_000) % 60,
    secs: Math.floor(t / 1000) % 60,
  };
}

/** Whether the prediction window is still open for a given kickoff. */
export function isPredictionOpen(kickoffIso: string, now = Date.now()): boolean {
  return now < new Date(kickoffIso).getTime() - LOCK_MS;
}

/** Time until KICKOFF (used by the top "Next match" bar). */
export function untilKickoff(kickoffIso: string, now = Date.now()): Parts {
  return split(new Date(kickoffIso).getTime() - now);
}

/** Time until the prediction window CLOSES (used by the in-card clock tab). */
export function untilLock(kickoffIso: string, now = Date.now()): Parts {
  return split(new Date(kickoffIso).getTime() - LOCK_MS - now);
}

export function formatKickoff(kickoffIso: string): string {
  const d = new Date(kickoffIso);
  const p = (n: number) => n.toString().padStart(2, '0');
  return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()} — ${p(d.getHours())}:${p(d.getMinutes())}`;
}

/** Stable day key (YYYY-MM-DD in local time) for grouping/filtering. */
export function dayKey(kickoffIso: string): string {
  const d = new Date(kickoffIso);
  const p = (n: number) => n.toString().padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

export function dayLabel(kickoffIso: string): string {
  const d = new Date(kickoffIso);
  return d.toLocaleDateString('en', { weekday: 'short', day: 'numeric', month: 'numeric' });
}

/** 1s ticker hook helper value — components use useEffect(setInterval). */
export const TICK_MS = 1000;

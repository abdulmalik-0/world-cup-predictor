import { useEffect, useState } from 'react';

// One shared timer per distinct interval, fanned out to all subscribers — so N
// match cards no longer each spin up their own setInterval (which meant N
// independent re-renders per tick). Ticks are also synchronised across cards.
type Sub = (now: number) => void;
const tickers = new Map<number, { subs: Set<Sub>; id: ReturnType<typeof setInterval> }>();

function subscribe(intervalMs: number, fn: Sub): () => void {
  let ticker = tickers.get(intervalMs);
  if (!ticker) {
    const subs = new Set<Sub>();
    const id = setInterval(() => {
      const now = Date.now();
      subs.forEach((s) => s(now));
    }, intervalMs);
    ticker = { subs, id };
    tickers.set(intervalMs, ticker);
  }
  ticker.subs.add(fn);
  return () => {
    ticker!.subs.delete(fn);
    if (ticker!.subs.size === 0) {
      clearInterval(ticker!.id);
      tickers.delete(intervalMs);
    }
  };
}

/** Re-renders every `intervalMs` so countdowns tick live (shared timer). */
export function useNow(intervalMs = 1000): number {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => subscribe(intervalMs, setNow), [intervalMs]);
  return now;
}

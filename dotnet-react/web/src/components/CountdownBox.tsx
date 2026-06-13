import { C } from '../lib/theme';

/**
 * FIFA-style flip box: a bold red number on a dark tile with a small uppercase
 * label below. Ported from the Flutter `_flipUnit`. Two sizes are used:
 *  - "bar"  → the top "Next match" countdown (38×34 tile, 19px digits)
 *  - "tab"  → the in-card clock tab (30×26 tile, 15px digits)
 */
export function CountdownBox({
  value,
  label,
  size = 'bar',
}: {
  value: number;
  label: string;
  size?: 'bar' | 'tab';
}) {
  const bar = size === 'bar';
  const text = value.toString().padStart(2, '0');
  return (
    <div className="flex flex-col items-center">
      <div
        className="flex items-center justify-center"
        style={{
          width: bar ? 38 : 30,
          height: bar ? 34 : 26,
          borderRadius: bar ? 6 : 5,
          background: `linear-gradient(${C.flipTop}, ${C.flipBottom})`,
          border: `1px solid ${hex(C.countdownRed, 0.3)}`,
          boxShadow: bar ? `0 0 10px -4px ${hex(C.countdownRed, 0.5)}` : 'none',
        }}
      >
        <span
          style={{
            color: C.countdownRed,
            fontWeight: 900,
            fontSize: bar ? 19 : 15,
            lineHeight: 1,
            letterSpacing: bar ? 1 : 0.8,
          }}
        >
          {text}
        </span>
      </div>
      <span
        className="mt-[3px] text-white/60"
        style={{ fontWeight: 700, fontSize: bar ? 8 : 7, letterSpacing: 0.8 }}
      >
        {label}
      </span>
    </div>
  );
}

/** hex + alpha → rgba() string. */
export function hex(h: string, a: number): string {
  const n = parseInt(h.slice(1), 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${a})`;
}

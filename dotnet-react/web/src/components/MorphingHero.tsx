import { motion, useScroll, useTransform } from 'framer-motion';
import { WcMask } from './WcMask';
import { useWindowSize } from '../hooks/useWindowSize';

const NAV_H = 66;
const ASPECT = 1115 / 428; // ≈ 2.605
const SMALL_H = 46; // landed height inside the navbar

/** easeInOutCubic */
function easeInOut(t: number) {
  return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
}

/**
 * MorphingHero — the "26 NEW YORK NEW JERSEY" masked video.
 *
 * At the top the page is WHITE with the big masked lockup centered (like
 * nynjfwc26.com). On scroll the white page fades away to reveal the dark
 * WE-ARE-26 background, while the clip shrinks AND flies into the centre of the
 * navbar — reversing on the way back up. (Ported from the Flutter morph.)
 */
export function MorphingHero() {
  const { scrollY } = useScroll();
  const { w: vw, h: vh } = useWindowSize();

  const bodyH = vh - NAV_H;
  const bigH = Math.min(bodyH * 0.52, (vw * 0.82) / ASPECT);
  const MORPH = Math.min(Math.max(bodyH * 0.82, 320), 760);

  // eased scroll progress 0 → 1
  const raw = useTransform(scrollY, [0, MORPH], [0, 1], { clamp: true });
  const t = useTransform(raw, easeInOut);

  const height = useTransform(t, (v) => bigH + (SMALL_H - bigH) * v);
  const width = useTransform(height, (h) => h * ASPECT);

  const bigCy = NAV_H + bodyH * 0.42;
  const smallCy = NAV_H / 2;
  const top = useTransform([t, height] as const, ([tv, h]: number[]) => {
    const cy = bigCy + (smallCy - bigCy) * tv;
    return cy - h / 2;
  });
  const left = useTransform(width, (w) => vw / 2 - w / 2);

  const whiteOpacity = useTransform(raw, [0, 0.7], [1, 0], { clamp: true });

  return (
    <>
      {/* Full-viewport white page that fades out as you scroll. Sits BELOW the
          navbar (z-40) so the navbar stays visible, and below the clip (z-50). */}
      <motion.div
        className="fixed inset-0 z-30 bg-white pointer-events-none"
        style={{ opacity: whiteOpacity }}
        aria-hidden
      />

      {/* The morphing masked clip, on top of everything. */}
      <div className="pointer-events-none fixed inset-0 z-50" aria-hidden>
        <motion.div style={{ position: 'absolute', top, left, width, height }}>
          <WcMask whiteOpacity={0} variant="horizontal" />
        </motion.div>
      </div>
    </>
  );
}

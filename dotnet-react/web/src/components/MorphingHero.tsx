import { motion, useScroll, useTransform } from 'framer-motion';
import { useLocation } from 'react-router-dom';
import { WcMask } from './WcMask';
import { useWindowSize } from '../hooks/useWindowSize';

const NAV_H = 66;
const MOBILE_BP = 768;
const H_ASPECT = 1115 / 428; // wide "26 NEW YORK NEW JERSEY"  ≈ 2.605
const V_ASPECT = 134 / 255; //  square-ish "2🏆6" emblem        ≈ 0.525
const SMALL_H = 46; // landed height inside the navbar

/** easeInOutCubic */
function easeInOut(t: number) {
  return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
}

/**
 * MorphingHero — the World Cup 26 masked video.
 *
 * Desktop: the wide "26 NEW YORK NEW JERSEY" lockup.
 * Mobile : the square "2🏆6" emblem (same responsive choice as the Flutter app).
 *
 * On the dashboard the page starts WHITE with the big masked lockup centered
 * (like nynjfwc26.com). On scroll the white page fades to reveal the dark
 * WE-ARE-26 background, while the clip shrinks AND flies into the navbar centre
 * — reversing on the way up. On other pages the clip just sits in the navbar.
 */
export function MorphingHero() {
  const { scrollY } = useScroll();
  const { w: vw, h: vh } = useWindowSize();
  const { pathname } = useLocation();
  const isMobile = vw < MOBILE_BP;
  const isDashboard = pathname === '/' || pathname.startsWith('/dashboard');

  const variant = isMobile ? 'vertical' : 'horizontal';
  const aspect = isMobile ? V_ASPECT : H_ASPECT;

  const bodyH = vh - NAV_H;
  const bigH = isMobile
    ? Math.min(bodyH * 0.42, (vw * 0.62) / aspect)
    : Math.min(bodyH * 0.52, (vw * 0.82) / aspect);
  const smallH = isMobile ? 50 : SMALL_H;
  const MORPH = Math.min(Math.max(bodyH * 0.82, 320), 760);

  // All hooks run unconditionally (Rules of Hooks); we branch only at render.
  const raw = useTransform(scrollY, [0, MORPH], [0, 1], { clamp: true });
  const t = useTransform(raw, easeInOut);
  const height = useTransform(t, (v) => bigH + (smallH - bigH) * v);
  const width = useTransform(height, (h) => h * aspect);

  const bigCy = NAV_H + bodyH * (isMobile ? 0.4 : 0.42);
  const smallCy = NAV_H / 2;
  const top = useTransform([t, height] as const, ([tv, h]: number[]) => {
    const cy = bigCy + (smallCy - bigCy) * tv;
    return cy - h / 2;
  });
  const left = useTransform(width, (w) => vw / 2 - w / 2);
  const whiteOpacity = useTransform(raw, [0, 0.7], [1, 0], { clamp: true });

  // Off the dashboard: park the small clip statically in the navbar centre.
  if (!isDashboard) {
    const w = smallH * aspect;
    return (
      <div className="pointer-events-none fixed inset-0 z-50" aria-hidden>
        <div
          style={{
            position: 'absolute',
            top: NAV_H / 2 - smallH / 2,
            left: vw / 2 - w / 2,
            width: w,
            height: smallH,
          }}
        >
          <WcMask whiteOpacity={0} variant={variant} />
        </div>
      </div>
    );
  }

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
          <WcMask whiteOpacity={0} variant={variant} />
        </motion.div>
      </div>
    </>
  );
}

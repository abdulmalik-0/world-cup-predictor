import { motion, useScroll, useTransform } from 'framer-motion';
import { useLocation } from 'react-router-dom';
import { WcMask } from './WcMask';
import { MaskedVideo } from './MaskedVideo';
import { useWindowSize } from '../hooks/useWindowSize';
import { useReducedMotion } from '../hooks/useReducedMotion';

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
 * Desktop: the wide "26 NEW YORK NEW JERSEY" lockup. Mobile: the square "2🏆6".
 *
 * The clip is rendered ONCE at its big size and morphs into the navbar purely
 * via GPU `scale` + `translateY` (no width/height/top changes), so scrolling
 * never triggers layout/paint — smooth even on phones. The white page fades on
 * scroll. Off the dashboard the clip just parks in the navbar.
 */
export function MorphingHero() {
  const { scrollY } = useScroll();
  const { w: vw, h: vh } = useWindowSize();
  const { pathname } = useLocation();
  const isMobile = vw < MOBILE_BP;
  const still = useReducedMotion(); // mobile or reduced-motion → still poster, no video
  const isDashboard = pathname === '/' || pathname.startsWith('/dashboard');

  const variant = isMobile ? 'vertical' : 'horizontal';
  const aspect = isMobile ? V_ASPECT : H_ASPECT;

  const bodyH = vh - NAV_H;
  // Mobile: make the "2🏆6" fill the screen (≈88% width); the height cap keeps it
  // from overflowing on short phones. Desktop unchanged.
  const bigH = isMobile
    ? Math.min(bodyH * 0.9, (vw * 0.88) / aspect)
    : Math.min(bodyH * 0.52, (vw * 0.82) / aspect);
  const bigW = bigH * aspect;
  const smallH = isMobile ? 50 : SMALL_H;
  const scaleSmall = smallH / bigH;
  const MORPH = Math.min(Math.max(bodyH * 0.82, 320), 760);

  const bigCy = NAV_H + bodyH * (isMobile ? 0.48 : 0.42);
  const smallCy = NAV_H / 2;

  // All hooks run unconditionally (Rules of Hooks); branch only at render.
  const raw = useTransform(scrollY, [0, MORPH], [0, 1], { clamp: true });
  const t = useTransform(raw, easeInOut);
  const scale = useTransform(t, (v) => 1 + (scaleSmall - 1) * v);
  const y = useTransform(t, (v) => (smallCy - bigCy) * v);
  const whiteOpacity = useTransform(raw, [0, 0.7], [1, 0], { clamp: true });

  // Static box (centred at bigCy); the morph is pure transform on top of it.
  const boxLeft = vw / 2 - bigW / 2;
  const boxTop = bigCy - bigH / 2;

  // Small "26" parked in the navbar centre (off-dashboard / desktop reduced-motion).
  const parkSmall = (() => {
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
          <WcMask whiteOpacity={0} variant={variant} still={still} />
        </div>
      </div>
    );
  })();

  if (!isDashboard) return parkSmall;

  // Reduced motion on DESKTOP only: no morph, just park the mark. (On mobile
  // `still` is always true — see useReducedMotion — but we still want the morph
  // there, so this short-circuits the desktop case alone.)
  if (still && !isMobile) return parkSmall;

  // ── MORPH (desktop + mobile) ───────────────────────────────────────────────
  // The clip starts big & centred over a white page, then shrinks into the
  // navbar via GPU scale + translateY as you scroll. Mobile renders the "2🏆6"
  // with a plain <video> + CSS mask (MaskedVideo) so it actually plays on iOS;
  // desktop keeps the wide <foreignObject> WcMask. The morph maths is identical.
  return (
    <>
      {/* Full-viewport white page that fades out as you scroll (GPU opacity). */}
      <motion.div
        className="fixed inset-0 z-30 bg-white pointer-events-none"
        style={{ opacity: whiteOpacity }}
        aria-hidden
      />

      {/* The masked clip — morphs via scale + translateY only. */}
      <div className="pointer-events-none fixed inset-0 z-50" aria-hidden>
        <motion.div
          style={{
            position: 'absolute',
            left: boxLeft,
            top: boxTop,
            width: bigW,
            height: bigH,
            transformOrigin: 'center center',
            willChange: 'transform',
            scale,
            y,
          }}
        >
          {isMobile ? (
            <MaskedVideo variant={variant} />
          ) : (
            <WcMask whiteOpacity={0} variant={variant} still={still} />
          )}
        </motion.div>
      </div>
    </>
  );
}

import { motion, useScroll, useTransform, MotionValue } from 'framer-motion';
import { useRef } from 'react';

/**
 * MorphingHero
 * ─────────────
 * Same idea as the Flutter `_MorphingClip`:
 *  - At the top of the dashboard the "26 NEW YORK NEW JERSEY" clip is a giant
 *    hero in the middle of the screen, with a looping video shown ONLY inside
 *    the "26" shape (SVG <clipPath> on a <video>).
 *  - On scroll, the clip smoothly shrinks AND moves up into the centre of the
 *    fixed navbar (between the EnterGame logo and the menu).
 *  - When you scroll back up, it reverses cleanly.
 *
 * The white surround fades out as the clip travels, so it lands cleanly on
 * the dark navbar without bringing a white halo.
 */
export function MorphingHero({
  videoSrc = '/hero.mp4',
  posterSrc = '/hero-poster.webp',
}: {
  videoSrc?: string;
  posterSrc?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollY } = useScroll();

  // The morph completes over `MORPH_DIST` px of scroll.
  const MORPH_DIST = 600;

  // Eased scroll progress (0 → 1).
  const t: MotionValue<number> = useTransform(scrollY, [0, MORPH_DIST], [0, 1], {
    clamp: true,
  });

  // Size: 480 px big → 46 px landed in navbar.
  const height = useTransform(t, (v) => 480 - (480 - 46) * easeInOut(v));
  const width  = useTransform(height, (h) => h * 2.55);

  // Vertical: starts ~42% down the screen, lands at navbar centre (33 px).
  const top = useTransform(t, (v) => {
    const big = window.innerHeight * 0.18;   // top of the big clip
    const small = 10;                        // top of the navbar landing
    return big - (big - small) * easeInOut(v);
  });

  // Horizontal: always centered (`left: 50%` + `x: -50%`).
  const whiteOpacity = useTransform(t, [0, 0.7], [1, 0], { clamp: true });

  return (
    <div ref={ref} className="pointer-events-none fixed inset-x-0 top-0 z-40">
      <motion.div
        style={{
          height,
          width,
          top,
          left: '50%',
          x: '-50%',
          position: 'absolute',
        }}
      >
        {/* SVG defines the "26" clipPath. Path data is the official lockup. */}
        <svg viewBox="0 0 1115 428" preserveAspectRatio="xMidYMid meet" className="w-full h-full">
          <defs>
            <clipPath id="wcShape" clipPathUnits="userSpaceOnUse">
              {/* Simplified silhouette of "26 + trophy + NEW YORK NEW JERSEY".
                  In production we paste the full path from wc_mask_paths.dart. */}
              <path d={SHAPE_D} />
            </clipPath>
          </defs>

          {/* The video, masked. */}
          <foreignObject x="0" y="0" width="1115" height="428" clipPath="url(#wcShape)">
            <video
              src={videoSrc}
              poster={posterSrc}
              autoPlay
              muted
              loop
              playsInline
              className="w-full h-full object-cover"
            />
          </foreignObject>
        </svg>

        {/* White surround that fades out (sits BEHIND the clip on the page). */}
        <motion.div
          aria-hidden
          className="absolute inset-0 -z-10"
          style={{ opacity: whiteOpacity, background: 'white' }}
        />
      </motion.div>
    </div>
  );
}

// easeInOutCubic
function easeInOut(t: number) {
  return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
}

// Placeholder shape — the real WC lockup path is ~20 KB and lives in
// `public/wc-shape.svg`. We import it at build time in production.
const SHAPE_D =
  'M0 0 H1115 V428 H0 Z M120 80 A 130 130 0 1 0 120 340 V 80 Z ' +
  'M520 80 H 990 A 60 60 0 0 1 1050 140 V 280 A 60 60 0 0 1 990 340 H 520 Z';

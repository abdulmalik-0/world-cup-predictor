import { motion } from 'framer-motion';
import { useReducedMotion } from '../hooks/useReducedMotion';

/**
 * "WE ARE 26" branded app background — ported from the Flutter
 * AnimatedBackground: black radial base, a pulsing gold glow, the bold
 * WE-ARE-26 lockup (with a real gold trophy between the digits), and a
 * vignette scrim so foreground content stays readable.
 *
 * Rendered FIXED behind everything (pointer-events: none). On mobile / reduced
 * motion the infinite glow + breathing loops are OFF (rendered static) to keep
 * the compositor idle.
 */
export function WeAre26Background() {
  const still = useReducedMotion();
  // Pulsing glow loop — disabled when motion is reduced.
  const glowAnim = still ? undefined : { scale: [0.9, 1.12, 0.9], opacity: [0.7, 1, 0.7] };
  const lockupAnim = still ? undefined : { scale: [1, 1.03, 1] };

  return (
    <div className="fixed inset-0 -z-10 overflow-hidden pointer-events-none select-none">
      {/* 1) Black base with a subtle warm center. */}
      <div
        className="absolute inset-0"
        style={{
          background:
            'radial-gradient(120% 130% at 50% 35%, #15110A 0%, #050505 55%, #000000 100%)',
        }}
      />

      {/* 2) Gold glow behind the lockup. */}
      <motion.div
        className="absolute left-1/2 top-1/2"
        style={{
          width: '70vw',
          height: '50vh',
          borderRadius: '50%',
          x: '-50%',
          y: '-50%',
          background:
            'radial-gradient(circle, rgba(233,184,74,0.22) 0%, rgba(233,184,74,0) 70%)',
        }}
        animate={glowAnim}
        transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
      />

      {/* 3) WE ARE 26 lockup, centered via framer x/y. */}
      <motion.div
        className="absolute left-1/2 top-1/2 flex flex-col items-center"
        style={{ width: '82vw', maxWidth: 980, x: '-50%', y: '-50%' }}
        animate={lockupAnim}
        transition={{ duration: 5.2, repeat: Infinity, ease: 'easeInOut' }}
      >
        <div
          className="font-black italic text-white leading-[0.9]"
          style={{ fontSize: 'clamp(28px, 9vw, 110px)', letterSpacing: '0.04em' }}
        >
          WE ARE
        </div>
        <div dir="ltr" className="flex items-center justify-center" style={{ gap: 'clamp(4px,2vw,18px)' }}>
          <span
            className="font-black text-white text-center leading-[0.9]"
            style={{ fontSize: 'clamp(80px, 26vw, 300px)', width: '0.7em' }}
          >
            2
          </span>
          <img
            src="/trophy.png"
            alt=""
            style={{ height: 'clamp(90px, 28vw, 320px)', objectFit: 'contain' }}
          />
          <span
            className="font-black text-white text-center leading-[0.9]"
            style={{ fontSize: 'clamp(80px, 26vw, 300px)', width: '0.7em' }}
          >
            6
          </span>
        </div>
        <div
          className="font-black text-white/90 leading-[0.9] mt-2"
          style={{ fontSize: 'clamp(20px, 6vw, 64px)', letterSpacing: '0.06em' }}
        >
          FIFA
        </div>
      </motion.div>

      {/* 4) Vignette / readability scrim. */}
      <div
        className="absolute inset-0"
        style={{
          background:
            'linear-gradient(180deg, rgba(0,0,0,0.70) 0%, rgba(0,0,0,0.30) 45%, rgba(0,0,0,0.80) 100%)',
        }}
      />
    </div>
  );
}

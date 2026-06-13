import { useEffect, useRef } from 'react';
import { WC_VERTICAL } from '../lib/wcMaskPaths';

const NAV_H = 66;

/** Shared height for the pinned hero AND the dashboard spacer (so content lines
 *  up exactly under it). */
export const mobileHeroHeight = (vh: number) =>
  Math.round(Math.min(Math.max((vh - NAV_H) * 0.52, 300), 460));

// CSS mask of the "2🏆6" shape (built once). A PLAIN <video> + CSS mask is used
// instead of a <video> inside <foreignObject>, because foreignObject video does
// NOT autoplay/render on iOS Safari — that's why the clip went black on phones.
const MASK_SVG =
  `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 ${WC_VERTICAL.w} ${WC_VERTICAL.h}'>` +
  `<path d='${WC_VERTICAL.path}' fill='%23fff' fill-rule='evenodd'/></svg>`;
const MASK = `url("data:image/svg+xml,${encodeURIComponent(MASK_SVG)}")`;

const maskStyle: React.CSSProperties = {
  WebkitMaskImage: MASK,
  maskImage: MASK,
  WebkitMaskRepeat: 'no-repeat',
  maskRepeat: 'no-repeat',
  WebkitMaskPosition: 'center',
  maskPosition: 'center',
  WebkitMaskSize: 'contain',
  maskSize: 'contain',
};

/**
 * MOBILE‑ONLY pinned / parallax hero.
 *
 * A real <video> (reliable iOS autoplay: muted + playsinline + autoplay, plus a
 * ref that forces `.muted` and calls `.play()`), masked to the "2🏆6" lockup via
 * CSS. The element is `position: fixed` under the navbar, so the dashboard
 * content scrolls UP over it (the video stays put). No scroll‑linked transforms,
 * so it stays smooth on phones.
 */
export function MobileHero({ vh }: { vh: number }) {
  const ref = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const v = ref.current;
    if (!v) return;
    v.muted = true; // React can drop the muted attribute; iOS needs it for autoplay
    const play = () => { const p = v.play(); if (p) p.catch(() => {}); };
    play();
    v.addEventListener('loadeddata', play, { once: true });
    // iOS low‑power mode blocks autoplay until a user gesture — resume on first tap.
    const onTouch = () => play();
    window.addEventListener('touchstart', onTouch, { once: true, passive: true });
    return () => window.removeEventListener('touchstart', onTouch);
  }, []);

  return (
    <div
      className="fixed left-0 right-0 pointer-events-none"
      style={{ top: NAV_H, height: mobileHeroHeight(vh), zIndex: 1 }}
      aria-hidden
    >
      <video
        ref={ref}
        src="/hero.mp4"
        poster="/hero-poster.webp"
        muted
        autoPlay
        loop
        playsInline
        preload="auto"
        style={{ width: '100%', height: '100%', objectFit: 'cover', ...maskStyle }}
      />
    </div>
  );
}

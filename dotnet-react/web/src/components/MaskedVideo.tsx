import { useEffect, useRef } from 'react';
import { WC_VERTICAL, WC_HORIZONTAL } from '../lib/wcMaskPaths';

// CSS masks of the "26" lockups, built once. A PLAIN <video> + CSS mask is used
// (instead of a <video> inside <foreignObject>, as WcMask does) because a
// foreignObject video does NOT autoplay or even render on iOS Safari — that's
// why the clip went black on phones.
function maskUrl(shape: { w: number; h: number; path: string }) {
  const svg =
    `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 ${shape.w} ${shape.h}'>` +
    `<path d='${shape.path}' fill='%23fff' fill-rule='evenodd'/></svg>`;
  return `url("data:image/svg+xml,${encodeURIComponent(svg)}")`;
}
const MASK_V = maskUrl(WC_VERTICAL);
const MASK_H = maskUrl(WC_HORIZONTAL);

/**
 * A real <video> masked to the "26" shape via CSS — fills its parent. The parent
 * controls size and the morph transform (scale + translateY); this just paints
 * the playing, masked video inside it.
 *
 * Used on mobile, where <video> inside <foreignObject> (see WcMask) does not
 * autoplay/render on iOS. iOS autoplay needs muted + playsinline + autoplay;
 * React can drop the muted attribute, so we also force `.muted = true` and call
 * `.play()` from a ref, and resume on first touch (covers iOS low-power mode).
 *
 * `translateZ(0)` promotes the masked video to its own compositing layer so the
 * parent's scale transform just scales the cached texture — Safari does NOT
 * re-rasterise the mask on every scroll frame, keeping the morph smooth.
 */
export function MaskedVideo({ variant }: { variant: 'vertical' | 'horizontal' }) {
  const ref = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const v = ref.current;
    if (!v) return;
    v.muted = true; // React can drop the muted attribute; iOS needs it for autoplay
    const play = () => { const p = v.play(); if (p) p.catch(() => {}); };
    play();
    v.addEventListener('loadeddata', play, { once: true });
    // iOS low-power mode blocks autoplay until a user gesture — resume on first tap.
    const onTouch = () => play();
    window.addEventListener('touchstart', onTouch, { once: true, passive: true });
    return () => window.removeEventListener('touchstart', onTouch);
  }, []);

  const mask = variant === 'vertical' ? MASK_V : MASK_H;
  return (
    <video
      ref={ref}
      src="/hero.mp4"
      poster="/hero-poster.webp"
      muted
      autoPlay
      loop
      playsInline
      preload="auto"
      style={{
        width: '100%',
        height: '100%',
        objectFit: 'cover',
        display: 'block',
        transform: 'translateZ(0)',
        WebkitMaskImage: mask,
        maskImage: mask,
        WebkitMaskRepeat: 'no-repeat',
        maskRepeat: 'no-repeat',
        WebkitMaskPosition: 'center',
        maskPosition: 'center',
        WebkitMaskSize: 'contain',
        maskSize: 'contain',
      }}
    />
  );
}

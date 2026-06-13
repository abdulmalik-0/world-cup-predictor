import { useId } from 'react';
import { WC_HORIZONTAL, WC_VERTICAL } from '../lib/wcMaskPaths';

/**
 * WcMask — the signature "26 NEW YORK NEW JERSEY" lockup with a looping video
 * revealed ONLY through the shape, plus a white surround that can fade out.
 *
 * Ported from the Flutter `WcMiniLogo` / `WcMaskedHero` (SVG clip-path + a
 * negative white mask). The video is clipped to the shape via a <foreignObject>
 * so it scales responsively with the viewBox.
 *
 * @param whiteOpacity 1 → solid white surround (start), 0 → just the video-in-26.
 */
export function WcMask({
  videoSrc = '/hero.mp4',
  posterSrc = '/hero-poster.webp',
  whiteOpacity = 0,
  still = false,
  variant = 'horizontal',
  className,
  style,
}: {
  videoSrc?: string;
  posterSrc?: string;
  whiteOpacity?: number;
  /** Paint the still poster instead of the live video (mobile / reduced motion). */
  still?: boolean;
  variant?: 'horizontal' | 'vertical';
  className?: string;
  style?: React.CSSProperties;
}) {
  const uid = useId().replace(/:/g, '');
  const shape = variant === 'vertical' ? WC_VERTICAL : WC_HORIZONTAL;
  const clipId = `wcClip-${uid}`;
  const maskId = `wcMask-${uid}`;

  return (
    <svg
      viewBox={`0 0 ${shape.w} ${shape.h}`}
      preserveAspectRatio="xMidYMid meet"
      className={className}
      style={{ width: '100%', height: '100%', display: 'block', ...style }}
    >
      <defs>
        <clipPath id={clipId} clipPathUnits="userSpaceOnUse">
          <path d={shape.path} fillRule="evenodd" />
        </clipPath>
        <mask id={maskId}>
          <rect x={0} y={0} width={shape.w} height={shape.h} fill="white" />
          <path d={shape.path} fill="black" fillRule="evenodd" />
        </mask>
      </defs>

      {/* The "26" reveal. On mobile / reduced-motion we paint a STILL poster
          (a ~30 KB image clipped to the shape) instead of decoding the 10 MB
          looping video through the clip-path every frame — that combo is what
          stalls phones. Desktop keeps the live video. */}
      {still ? (
        <image
          href={posterSrc}
          x={0}
          y={0}
          width={shape.w}
          height={shape.h}
          clipPath={`url(#${clipId})`}
          preserveAspectRatio="xMidYMid slice"
        />
      ) : (
        <foreignObject x={0} y={0} width={shape.w} height={shape.h} clipPath={`url(#${clipId})`}>
          <video
            src={videoSrc}
            poster={posterSrc}
            autoPlay
            muted
            loop
            playsInline
            // @ts-expect-error xmlns is valid on the HTML element inside foreignObject
            xmlns="http://www.w3.org/1999/xhtml"
            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
          />
        </foreignObject>
      )}

      {/* White surround (everything EXCEPT the 26), fades out on scroll. */}
      {whiteOpacity > 0.01 && (
        <rect
          x={0}
          y={0}
          width={shape.w}
          height={shape.h}
          fill="white"
          mask={`url(#${maskId})`}
          opacity={whiteOpacity}
        />
      )}
    </svg>
  );
}

/**
 * Just the white negative surround (white everywhere EXCEPT the "26" hole),
 * as its own static SVG. Wrap it in a motion element and animate THAT element's
 * opacity — so scrolling never re-renders the heavy path.
 */
export function WcWhiteSurround({
  variant = 'horizontal',
  className,
  style,
}: {
  variant?: 'horizontal' | 'vertical';
  className?: string;
  style?: React.CSSProperties;
}) {
  const uid = useId().replace(/:/g, '');
  const shape = variant === 'vertical' ? WC_VERTICAL : WC_HORIZONTAL;
  const maskId = `wcNeg-${uid}`;
  return (
    <svg
      viewBox={`0 0 ${shape.w} ${shape.h}`}
      preserveAspectRatio="xMidYMid meet"
      className={className}
      style={{ width: '100%', height: '100%', display: 'block', ...style }}
    >
      <defs>
        <mask id={maskId}>
          <rect x={0} y={0} width={shape.w} height={shape.h} fill="white" />
          <path d={shape.path} fill="black" fillRule="evenodd" />
        </mask>
      </defs>
      <rect x={0} y={0} width={shape.w} height={shape.h} fill="white" mask={`url(#${maskId})`} />
    </svg>
  );
}

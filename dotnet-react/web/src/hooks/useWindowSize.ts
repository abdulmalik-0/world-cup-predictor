import { useEffect, useState } from 'react';

/** Tracks the viewport size and updates on resize (responsive layouts). */
export function useWindowSize() {
  const [size, setSize] = useState(() => ({
    w: typeof window !== 'undefined' ? window.innerWidth : 1280,
    h: typeof window !== 'undefined' ? window.innerHeight : 800,
  }));
  useEffect(() => {
    let raf = 0;
    const onResize = () => {
      if (raf) return; // coalesce resize bursts (e.g. mobile URL-bar show/hide) to 1/frame
      raf = requestAnimationFrame(() => {
        raf = 0;
        setSize((prev) =>
          prev.w === window.innerWidth && prev.h === window.innerHeight
            ? prev // no change → skip the re-render entirely
            : { w: window.innerWidth, h: window.innerHeight },
        );
      });
    };
    window.addEventListener('resize', onResize);
    return () => {
      window.removeEventListener('resize', onResize);
      if (raf) cancelAnimationFrame(raf);
    };
  }, []);
  return size;
}

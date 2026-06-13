import { useEffect, useState } from 'react';

const MOBILE_BP = 768;

function compute(): boolean {
  if (typeof window === 'undefined') return false;
  const reduced = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;
  return window.innerWidth <= MOBILE_BP || reduced;
}

/**
 * True when heavy animations should be OFF — i.e. on mobile (≤768px) or when
 * the OS asks for reduced motion. Components use this to skip framer-motion
 * infinite loops / entrance animations that cause jank on phones.
 */
export function useReducedMotion(): boolean {
  const [reduced, setReduced] = useState(compute);
  useEffect(() => {
    const onChange = () => setReduced(compute());
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    mq.addEventListener('change', onChange);
    window.addEventListener('resize', onChange);
    return () => {
      mq.removeEventListener('change', onChange);
      window.removeEventListener('resize', onChange);
    };
  }, []);
  return reduced;
}

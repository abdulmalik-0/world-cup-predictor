import { JERSEY } from './theme';

/**
 * Flag slug overrides for non-ISO internal codes (UK home nations).
 * Everything else derives from the lowercase 2-letter code.
 */
const FLAG_SLUG: Record<string, string> = {
  EN: 'gb-eng',
  SF: 'gb-sct',
  WAL: 'gb-wls',
  NIR: 'gb-nir',
};

export function flagUrl(code: string): string {
  const c = (code ?? '').trim();
  const slug = FLAG_SLUG[c.toUpperCase()] ?? (/^[A-Za-z]{2}$/.test(c) ? c.toLowerCase() : null);
  return slug ? `https://flagcdn.com/w160/${slug}.png` : '';
}

/** Stable per-team jersey colour (matches Flutter's hashCode % palette). */
export function jerseyColor(code: string): string {
  // Java/Dart-style string hashCode so colours line up with the Flutter app.
  let h = 0;
  for (let i = 0; i < code.length; i++) {
    h = (31 * h + code.charCodeAt(i)) | 0;
  }
  return JERSEY[Math.abs(h) % JERSEY.length];
}

export const isSaudi = (code: string) => code?.toUpperCase() === 'SA';

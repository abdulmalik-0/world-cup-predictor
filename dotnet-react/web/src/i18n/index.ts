import { useSyncExternalStore } from 'react';
import { STR, type StrKey } from './strings';

export type Lang = 'en' | 'ar';

// ── Tiny reactive store ─────────────────────────────────────────────────────
// The language lives in a module variable (mirrored to localStorage). Changing
// it notifies subscribers, so the UI updates INSTANTLY via a normal re-render —
// no full page reload, no remount, scroll position preserved.
let currentLang: Lang = readInitial();
const listeners = new Set<() => void>();

function readInitial(): Lang {
  if (typeof localStorage === 'undefined') return 'en';
  return localStorage.getItem('eg.lang') === 'ar' ? 'ar' : 'en';
}

export function getLang(): Lang {
  return currentLang;
}

export function setLang(lang: Lang) {
  if (lang === currentLang) return;
  currentLang = lang;
  if (typeof localStorage !== 'undefined') localStorage.setItem('eg.lang', lang);
  applyDir(lang);
  listeners.forEach((notify) => notify()); // → instant client-side re-render
}

export function toggleLang() {
  setLang(currentLang === 'en' ? 'ar' : 'en');
}

export function applyDir(lang: Lang = currentLang) {
  if (typeof document === 'undefined') return;
  document.documentElement.lang = lang;
  // Layout stays LTR in BOTH languages — only the text translates. This keeps
  // every element (logo, nav, score bug) in the exact same place when Arabic
  // is selected, instead of mirroring the whole UI.
  document.documentElement.dir = 'ltr';
}

/** Translate a key for the current language. */
export function t(key: StrKey): string {
  return STR[key][currentLang];
}

/** Locale tag for Intl/Date formatting. */
export function localeTag(): string {
  return currentLang === 'ar' ? 'ar' : 'en';
}

// ── React binding ───────────────────────────────────────────────────────────
function subscribe(cb: () => void): () => void {
  listeners.add(cb);
  return () => { listeners.delete(cb); };
}

/**
 * Subscribe to the current language. Any component that calls this re-renders
 * the instant the language flips. Calling it once near the app root re-renders
 * the whole tree, so every `t()` picks up the new strings live.
 */
export function useLang(): Lang {
  return useSyncExternalStore(subscribe, getLang, getLang);
}

export function useI18n() {
  const lang = useLang();
  return { lang, t, dir: 'ltr' as const };
}

import { STR, type StrKey } from './strings';

export type Lang = 'en' | 'ar';

export function getLang(): Lang {
  if (typeof localStorage === 'undefined') return 'en';
  return localStorage.getItem('eg.lang') === 'ar' ? 'ar' : 'en';
}

export function setLang(lang: Lang) {
  localStorage.setItem('eg.lang', lang);
  applyDir(lang);
}

export function applyDir(lang: Lang = getLang()) {
  if (typeof document === 'undefined') return;
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
}

/** Translate a key for the current language. */
export function t(key: StrKey): string {
  return STR[key][getLang()];
}

/** Locale tag for Intl/Date formatting. */
export function localeTag(): string {
  return getLang() === 'ar' ? 'ar' : 'en';
}

/**
 * Small hook so components re-read language on each render. Language changes
 * trigger a full reload (see the navbar chip), so a plain read is enough.
 */
export function useI18n() {
  const lang = getLang();
  return { lang, t, dir: lang === 'ar' ? ('rtl' as const) : ('ltr' as const) };
}

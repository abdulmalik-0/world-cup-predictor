import { useEffect, useRef, useState } from 'react';
import { NavLink } from 'react-router-dom';
import { t, toggleLang, useLang } from '../i18n';

const LINKS = [
  { to: '/dashboard', key: 'matches' as const },
  { to: '/past', key: 'pastMatches' as const },
  { to: '/leaderboard', key: 'leaderboard' as const },
  { to: '/stats', key: 'myStats' as const },
];

/**
 * Fixed top navigation bar. The MorphingHero clip lands in the centre gap.
 * Desktop: inline links on the right. Mobile: a ☰ menu (top-right) that opens
 * a dropdown, and a smaller EnterGame logo so the shrunk clip never overlaps it.
 */
export function Navbar() {
  return (
    <header className="fixed inset-x-0 top-0 z-40 h-[66px] bg-black/95 border-b border-white/10 px-3 sm:px-4 flex items-center gap-2 sm:gap-3 text-white">
      <EnterGameLogo />
      {/* Desktop: language chip on the left, next to the logo. */}
      <LangChip className="hidden md:flex" />

      {/* spacer that holds the morphing clip's landing spot */}
      <div className="flex-1" aria-hidden />

      {/* Desktop: inline links + logout */}
      <nav className="hidden md:flex items-center gap-1">
        {LINKS.map((l) => (
          <NavTab key={l.to} to={l.to} label={t(l.key)} />
        ))}
        <LogoutButton className="ml-2" />
      </nav>

      {/* Mobile: language chip + hamburger, both on the right. */}
      <div className="flex items-center gap-2 md:hidden">
        <LangChip />
        <MobileMenu />
      </div>
    </header>
  );
}

function EnterGameLogo() {
  return (
    <a href="/" className="flex items-center gap-2 select-none shrink-0">
      <img src="/entergame_logo.png" alt="EnterGame" className="h-5 sm:h-7 md:h-8" />
    </a>
  );
}

function LangChip({ className = '' }: { className?: string }) {
  const lang = useLang(); // re-renders this chip instantly on toggle
  return (
    <button
      onClick={toggleLang} // instant, client-side — no page reload
      className={`h-7 w-7 sm:h-8 sm:w-8 rounded-full border border-emerald-400/50 text-[10px] font-extrabold flex items-center justify-center hover:bg-white/10 shrink-0 ${className}`}
      aria-label="Toggle language"
    >
      {lang === 'en' ? 'عربي' : 'Eng'}
    </button>
  );
}

function NavTab({ to, label, onClick }: { to: string; label: string; onClick?: () => void }) {
  return (
    <NavLink
      to={to}
      onClick={onClick}
      className={({ isActive }) =>
        `relative px-3 py-2 text-sm font-bold transition ${
          isActive ? 'text-gold' : 'text-white/85 hover:text-white'
        }`
      }
    >
      {({ isActive }) => (
        <>
          {label}
          <span
            className={`absolute left-1/2 -translate-x-1/2 bottom-1 h-[2.5px] rounded bg-gold transition-all ${
              isActive ? 'w-5' : 'w-0'
            }`}
          />
        </>
      )}
    </NavLink>
  );
}

function LogoutButton({ className = '' }: { className?: string }) {
  return (
    <button
      onClick={() => {
        localStorage.removeItem('eg.token');
        location.href = '/login';
      }}
      className={`p-2 rounded hover:bg-white/10 ${className}`}
      aria-label="Sign out"
    >
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
           strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
        <polyline points="16 17 21 12 16 7" />
        <line x1="21" y1="12" x2="9" y2="12" />
      </svg>
    </button>
  );
}

function MobileMenu() {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', onDoc);
    return () => document.removeEventListener('mousedown', onDoc);
  }, [open]);

  return (
    <div className="md:hidden relative shrink-0" ref={ref}>
      <button
        onClick={() => setOpen((v) => !v)}
        className="p-2 rounded-lg hover:bg-white/10"
        aria-label="Open menu"
        aria-expanded={open}
      >
        {/* three lines */}
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             strokeWidth="2.2" strokeLinecap="round">
          <line x1="3" y1="6" x2="21" y2="6" />
          <line x1="3" y1="12" x2="21" y2="12" />
          <line x1="3" y1="18" x2="21" y2="18" />
        </svg>
      </button>

      {open && (
        <div
          className="absolute right-0 top-[calc(100%+8px)] w-52 rounded-xl overflow-hidden border border-white/15 shadow-2xl"
          style={{ background: '#0B1118' }}
        >
          {LINKS.map((l) => (
            <NavLink
              key={l.to}
              to={l.to}
              onClick={() => setOpen(false)}
              className={({ isActive }) =>
                `block px-4 py-3 text-sm font-bold border-b border-white/8 ${
                  isActive ? 'text-gold bg-white/5' : 'text-white/90 hover:bg-white/10'
                }`
              }
            >
              {t(l.key)}
            </NavLink>
          ))}
          <button
            onClick={() => {
              localStorage.removeItem('eg.token');
              location.href = '/login';
            }}
            className="w-full text-left px-4 py-3 text-sm font-bold text-white/80 hover:bg-white/10 flex items-center gap-2"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line x1="21" y1="12" x2="9" y2="12" />
            </svg>
            {t('signOut')}
          </button>
        </div>
      )}
    </div>
  );
}

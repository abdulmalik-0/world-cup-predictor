import { NavLink } from 'react-router-dom';

/**
 * Fixed top navigation bar. The MorphingHero clip lands in the centre gap
 * (between the EnterGame logo + language switcher on the left and the section
 * links + logout on the right).
 */
export function Navbar() {
  return (
    <header className="fixed inset-x-0 top-0 z-50 h-[66px] bg-black/95 border-b border-white/10 px-4 flex items-center text-white">
      <EnterGameLogo />
      <LangChip />

      {/* spacer that holds the morphing clip's landing spot */}
      <div className="flex-1" aria-hidden />

      <nav className="flex items-center gap-1">
        <NavTab to="/dashboard"  label="Matches" />
        <NavTab to="/leaderboard" label="Leaderboard" />
        <NavTab to="/stats"       label="My Stats" />
      </nav>

      <button
        onClick={() => { localStorage.removeItem('eg.token'); location.href = '/login'; }}
        className="ml-2 p-2 rounded hover:bg-white/10"
        aria-label="Sign out"
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
          <polyline points="16 17 21 12 16 7" />
          <line x1="21" y1="12" x2="9" y2="12" />
        </svg>
      </button>
    </header>
  );
}

function EnterGameLogo() {
  return (
    <a href="/" className="flex items-center gap-2 select-none">
      <img src="/entergame_logo.png" alt="EnterGame" className="h-7" />
    </a>
  );
}

function LangChip() {
  const lang = (localStorage.getItem('eg.lang') ?? 'en') as 'en' | 'ar';
  const toggle = () => {
    localStorage.setItem('eg.lang', lang === 'en' ? 'ar' : 'en');
    location.reload();
  };
  return (
    <button
      onClick={toggle}
      className="ml-3 h-8 w-8 rounded-full border border-emerald-400/50 text-[10px] font-extrabold flex items-center justify-center hover:bg-white/10"
    >
      {lang === 'en' ? 'عربي' : 'Eng'}
    </button>
  );
}

function NavTab({ to, label }: { to: string; label: string }) {
  return (
    <NavLink
      to={to}
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

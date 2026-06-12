import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '../lib/supabase';
import { useLang, toggleLang, t } from '../i18n';
import { useReducedMotion } from '../hooks/useReducedMotion';

type Mode = 'signin' | 'signup';

// Exact accent from the reference (Flutter) build.
const TEAL = '#14E3B4';

/**
 * Email + password auth — sized & styled to match the reference Flutter login
 * (entergame.altamimi.tech): 420px card, teal accent, 150px trophy with a gentle
 * float. Sign in ⇄ Sign up animate height inside the same card.
 */
export function Login() {
  const lang = useLang();
  const still = useReducedMotion();
  const [mode, setMode] = useState<Mode>('signin'); // default = Sign In
  const [fullName, setFullName] = useState('');
  const [department, setDepartment] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const isSignup = mode === 'signup';

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null); setNotice(null);
    if (isSignup && password !== confirm) { setError(t('passwordsMismatch')); return; }
    setBusy(true);
    try {
      if (!isSignup) {
        const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
        if (error) setError(t('authError'));
      } else {
        const { data, error } = await supabase.auth.signUp({
          email: email.trim(),
          password,
          options: { data: { full_name: fullName.trim(), department: department.trim() } },
        });
        if (error) setError(error.message);
        else if (!data.session) { setNotice(t('signUpConfirm')); setMode('signin'); }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  const toggle = () => { setMode(isSignup ? 'signin' : 'signup'); setError(null); setNotice(null); };

  // Google OAuth — works for both sign in and sign up (new accounts are
  // created automatically, with the name pulled from the Google profile).
  const google = async () => {
    setError(null);
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin },
    });
    if (error) setError(error.message);
    // on success the browser redirects to Google, then back into the app.
  };

  return (
    <main className="min-h-[100svh] flex items-center justify-center px-6 py-14">
      {/* Language toggle — top-left, like the reference. */}
      <button
        onClick={toggleLang}
        className="fixed top-3 left-3 z-10 h-9 w-9 rounded-full text-[11px] font-extrabold flex items-center justify-center
                   text-white hover:bg-white/10 transition"
        style={{ border: `1px solid ${TEAL}80` }}
        aria-label="Toggle language"
      >
        {lang === 'en' ? 'عربي' : 'Eng'}
      </button>

      <motion.form
        layout
        transition={{ layout: { type: 'spring', stiffness: 260, damping: 30 } }}
        onSubmit={submit}
        className="w-full max-w-[420px] px-6 py-7 overflow-hidden"
        style={{
          background: 'rgba(11,17,24,0.90)',
          borderRadius: 20,
          border: `1px solid ${TEAL}4D`,
          boxShadow: `0 0 40px -6px ${TEAL}1F, 0 14px 32px rgba(0,0,0,0.55)`,
        }}
      >
        {/* ── Brand header (logos kept as the app's existing assets) ── */}
        <motion.div layout="position" className="flex flex-col items-center">
          <motion.div
            className="relative"
            initial={{ opacity: 0, scale: 0.85 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          >
            <motion.img
              src="/wc26_logo.webp"
              alt="World Cup 2026"
              className="h-[150px] object-contain"
              animate={still ? undefined : { y: [-5, 5] }}
              transition={{ duration: 2.6, repeat: Infinity, repeatType: 'reverse', ease: 'easeInOut' }}
            />
          </motion.div>

          <motion.div
            className="flex flex-col items-center"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.18, ease: 'easeOut' }}
          >
            <img src="/entergame_logo.webp" alt="EnterGame" decoding="async" className="h-14 object-contain mt-5" />
            {/* "World Cup Arena" stays English in both languages (not translated). */}
            <h1 className="text-[22px] font-black tracking-wide mt-3">World Cup Arena</h1>
          </motion.div>

          <AnimatePresence mode="wait">
            <motion.p
              key={mode}
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -4 }}
              transition={{ duration: 0.2 }}
              className="text-[14px] text-white/55 text-center mt-2"
            >
              {isSignup ? t('signUpSubtitle') : t('signInSubtitle')}
            </motion.p>
          </AnimatePresence>
        </motion.div>

        {/* ── Continue with Google ── */}
        <motion.button
          layout
          type="button"
          onClick={google}
          whileTap={{ scale: 0.98 }}
          className="w-full mt-7 h-[50px] rounded-xl bg-white text-[#1F1F1F] font-bold text-[15px]
                     flex items-center justify-center gap-3 hover:bg-white/90 transition"
        >
          <GoogleIcon /> {t('googleCta')}
        </motion.button>

        <motion.div layout className="flex items-center gap-3 my-4">
          <span className="flex-1 h-px bg-white/12" />
          <span className="text-[12px] text-white/40">{t('orDivider')}</span>
          <span className="flex-1 h-px bg-white/12" />
        </motion.div>

        {/* ── Fields ── */}
        <motion.div layout className="space-y-4">
          <Collapsible show={isSignup}>
            <Field icon={<UserIcon />} placeholder={t('fullNameField')} value={fullName} onChange={setFullName} autoComplete="name" />
          </Collapsible>
          <Collapsible show={isSignup}>
            <Field icon={<BuildingIcon />} placeholder={t('departmentField')} value={department} onChange={setDepartment} />
          </Collapsible>

          <Field icon={<MailIcon />} type="email" placeholder={t('email')} value={email} onChange={setEmail} autoComplete="email" required />

          <Field
            icon={<LockIcon />} placeholder={t('password')} value={password} onChange={setPassword}
            type={showPw ? 'text' : 'password'}
            autoComplete={isSignup ? 'new-password' : 'current-password'} required
            trailing={
              <button type="button" onClick={() => setShowPw((v) => !v)} className="text-white/50 hover:text-white/90" tabIndex={-1} aria-label="Toggle password">
                {showPw ? <EyeOffIcon /> : <EyeIcon />}
              </button>
            }
          />

          <Collapsible show={isSignup}>
            <Field icon={<LockIcon />} type={showPw ? 'text' : 'password'} placeholder={t('confirmPassword')} value={confirm} onChange={setConfirm} autoComplete="new-password" />
          </Collapsible>
        </motion.div>

        {(error || notice) && (
          <motion.p layout className={`text-[13px] mt-3 text-center ${error ? 'text-red-300' : 'text-emerald-300'}`}>
            {error || notice}
          </motion.p>
        )}

        <motion.button
          layout
          type="submit"
          disabled={busy}
          whileTap={{ scale: 0.98 }}
          className="w-full mt-5 rounded-xl font-extrabold text-[16px] flex items-center justify-center disabled:opacity-50"
          style={{ background: TEAL, color: '#05070B', height: 50 }}
        >
          {busy ? t('working') : isSignup ? t('signUpCtaFull') : t('signInCta')}
        </motion.button>

        <motion.button layout type="button" onClick={toggle} className="w-full mt-3 text-[14px] hover:underline" style={{ color: TEAL }}>
          {isSignup ? t('haveAccount') : t('firstTime')}
        </motion.button>
      </motion.form>
    </main>
  );
}

/** Animated height/opacity wrapper for the sign-up-only fields. */
function Collapsible({ show, children }: { show: boolean; children: React.ReactNode }) {
  return (
    <AnimatePresence initial={false}>
      {show && (
        <motion.div
          initial={{ height: 0, opacity: 0 }}
          animate={{ height: 'auto', opacity: 1 }}
          exit={{ height: 0, opacity: 0 }}
          transition={{ duration: 0.28, ease: 'easeInOut' }}
          style={{ overflow: 'hidden' }}
        >
          {children}
        </motion.div>
      )}
    </AnimatePresence>
  );
}

function Field({
  icon, placeholder, value, onChange, type = 'text', autoComplete, required, trailing,
}: {
  icon: React.ReactNode; placeholder: string; value: string; onChange: (v: string) => void;
  type?: string; autoComplete?: string; required?: boolean; trailing?: React.ReactNode;
}) {
  return (
    <div className="relative" dir="ltr">
      <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-white/45 pointer-events-none">{icon}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        autoComplete={autoComplete}
        required={required}
        className="w-full rounded-xl border border-white/10 pl-11 pr-11 text-white placeholder-white/40 outline-none
                   focus:border-[#14E3B4]/70 transition"
        style={{ background: '#0F2032', height: 52 }}
      />
      {trailing && <span className="absolute right-3 top-1/2 -translate-y-1/2">{trailing}</span>}
    </div>
  );
}

// ── Icons (inline, 18px) ────────────────────────────────────────────────────
const sv = { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 1.8, strokeLinecap: 'round' as const, strokeLinejoin: 'round' as const };
const UserIcon = () => (<svg {...sv}><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>);
const BuildingIcon = () => (<svg {...sv}><rect x="4" y="3" width="16" height="18" rx="1.5" /><path d="M9 7h.01M15 7h.01M9 11h.01M15 11h.01M9 15h.01M15 15h.01M9 21v-3h6v3" /></svg>);
const MailIcon = () => (<svg {...sv}><rect x="3" y="5" width="18" height="14" rx="2" /><path d="m3 7 9 6 9-6" /></svg>);
const LockIcon = () => (<svg {...sv}><rect x="4" y="11" width="16" height="10" rx="2" /><path d="M8 11V7a4 4 0 0 1 8 0v4" /></svg>);
const EyeIcon = () => (<svg {...sv}><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z" /><circle cx="12" cy="12" r="3" /></svg>);
const EyeOffIcon = () => (<svg {...sv}><path d="M9.9 4.2A10.9 10.9 0 0 1 12 4c6.5 0 10 7 10 7a13.2 13.2 0 0 1-2.7 3.3M6.6 6.6A13.3 13.3 0 0 0 2 11s3.5 7 10 7a10.8 10.8 0 0 0 3.5-.6M3 3l18 18" /></svg>);
const GoogleIcon = () => (
  <svg width="19" height="19" viewBox="0 0 48 48" aria-hidden>
    <path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3c-1.6 4.7-6 8-11.3 8a12 12 0 1 1 7.9-21l5.7-5.7A20 20 0 1 0 24 44c11 0 20-8 20-20 0-1.2-.1-2.4-.4-3.5Z" />
    <path fill="#FF3D00" d="M6.3 14.7l6.6 4.8A12 12 0 0 1 24 12c3.1 0 5.9 1.2 8 3.1l5.7-5.7A20 20 0 0 0 6.3 14.7Z" />
    <path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2A12 12 0 0 1 12.7 28l-6.5 5A20 20 0 0 0 24 44Z" />
    <path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3a12 12 0 0 1-4.1 5.6l6.2 5.2C39.9 35.6 44 30.4 44 24c0-1.2-.1-2.4-.4-3.5Z" />
  </svg>
);

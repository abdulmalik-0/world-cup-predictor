import { useState } from 'react';
import { supabase } from '../lib/supabase';
import { C } from '../lib/theme';
import { useLang, t } from '../i18n';

type Mode = 'signin' | 'signup';

/**
 * Email + password login (Supabase Auth, reusing the existing accounts). Shown
 * full-screen over the branded background until the user is authenticated.
 */
export function Login() {
  useLang(); // re-render on language toggle
  const [mode, setMode] = useState<Mode>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [department, setDepartment] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true); setError(null); setNotice(null);
    try {
      if (mode === 'signin') {
        const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
        if (error) { setError(t('authError')); }
        // success → onAuthStateChange flips the gate to the app.
      } else {
        const { data, error } = await supabase.auth.signUp({
          email: email.trim(),
          password,
          options: { data: { full_name: fullName.trim(), department: department.trim() } },
        });
        if (error) { setError(error.message); }
        else if (data.session) { /* auto-confirmed → logged in */ }
        else { setNotice(t('signUpConfirm')); setMode('signin'); }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="min-h-[100svh] flex items-center justify-center px-4 py-16">
      <form
        onSubmit={submit}
        className="glass rounded-3xl w-full max-w-[400px] p-6 sm:p-8"
      >
        <div className="flex flex-col items-center mb-6">
          <img src="/entergame_logo.png" alt="EnterGame" className="h-9 mb-4" />
          <h1 className="text-xl font-extrabold text-center">
            {mode === 'signin' ? t('signInTitle') : t('signUpTitle')}
          </h1>
        </div>

        {mode === 'signup' && (
          <>
            <Field label={t('fullNameField')} value={fullName} onChange={setFullName} autoComplete="name" />
            <Field label={t('departmentField')} value={department} onChange={setDepartment} />
          </>
        )}
        <Field label={t('email')} type="email" value={email} onChange={setEmail} autoComplete="email" required />
        <Field label={t('password')} type="password" value={password} onChange={setPassword}
               autoComplete={mode === 'signin' ? 'current-password' : 'new-password'} required />

        {error && <p className="text-red-300 text-[13px] mb-3 text-center">{error}</p>}
        {notice && <p className="text-emerald-300 text-[13px] mb-3 text-center">{notice}</p>}

        <button
          type="submit"
          disabled={busy}
          className="w-full py-3 rounded-xl font-extrabold disabled:opacity-50 flex items-center justify-center gap-2"
          style={{ background: C.primaryGreen, color: '#fff' }}
        >
          {busy ? t('working') : mode === 'signin' ? t('signInCta') : t('signUpCta')}
        </button>

        <button
          type="button"
          onClick={() => { setMode(mode === 'signin' ? 'signup' : 'signin'); setError(null); setNotice(null); }}
          className="w-full mt-4 text-[13px] text-white/65 hover:text-white"
        >
          {mode === 'signin' ? t('noAccount') : t('haveAccount')}
        </button>
      </form>
    </main>
  );
}

function Field({
  label, value, onChange, type = 'text', autoComplete, required,
}: {
  label: string; value: string; onChange: (v: string) => void;
  type?: string; autoComplete?: string; required?: boolean;
}) {
  return (
    <label className="block mb-3.5">
      <span className="block text-[12px] text-white/60 mb-1.5">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        autoComplete={autoComplete}
        required={required}
        className="w-full rounded-xl bg-black/40 border border-white/15 px-3.5 py-3 text-white outline-none
                   focus:border-emerald-400 transition"
      />
    </label>
  );
}

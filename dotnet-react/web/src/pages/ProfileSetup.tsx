import { useEffect, useState } from 'react';
import { upsertProfile } from '../lib/auth';
import { useAuth } from '../hooks/useAuth';
import { useProfile } from '../hooks/useProfile';
import { setIdentity } from '../lib/identity';
import { t } from '../i18n';

const TEAL = '#14E3B4';

export function ProfileSetup({ onDone }: { onDone: () => void }) {
  const { user } = useAuth();
  const { profile } = useProfile(user?.id);
  const [fullName, setFullName] = useState('');
  const [department, setDepartment] = useState('');
  const [initialized, setInitialized] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!profile || initialized) return;
    if (profile.full_name !== 'موظف جديد') setFullName(profile.full_name);
    if (profile.department !== 'غير محدد') setDepartment(profile.department);
    setInitialized(true);
  }, [profile, initialized]);

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (fullName.trim().length < 2) { setError(t('errName')); return; }
    if (!department.trim()) { setError(t('errDept')); return; }

    setBusy(true);
    setError(null);
    try {
      const row = await upsertProfile(fullName, department);
      setIdentity(row.id, row.full_name);
      onDone();
    } catch {
      setError(t('errSaveProfile'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="min-h-[100svh] flex items-center justify-center px-6 py-14">
      <form
        onSubmit={save}
        className="w-full max-w-[420px] px-6 py-7"
        style={{
          background: 'rgba(11,17,24,0.90)',
          borderRadius: 20,
          border: `1px solid ${TEAL}4D`,
          boxShadow: `0 0 40px -6px ${TEAL}1F, 0 14px 32px rgba(0,0,0,0.55)`,
        }}
      >
        <h1 className="text-[22px] font-black text-center">{t('completeProfile')}</h1>
        <p className="text-[15px] font-bold text-center mt-2">{t('lastStep')}</p>
        <p className="text-[13px] text-white/55 text-center mt-1">{t('profileHint')}</p>

        <div className="space-y-4 mt-7" dir="ltr">
          <input
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            placeholder={t('fullNameField')}
            autoComplete="name"
            className="w-full rounded-xl border border-white/10 px-4 text-white placeholder-white/40 outline-none focus:border-[#14E3B4]/70 transition"
            style={{ background: '#0F2032', height: 52 }}
          />
          <input
            value={department}
            onChange={(e) => setDepartment(e.target.value)}
            placeholder={t('departmentField')}
            className="w-full rounded-xl border border-white/10 px-4 text-white placeholder-white/40 outline-none focus:border-[#14E3B4]/70 transition"
            style={{ background: '#0F2032', height: 52 }}
          />
        </div>

        {error && <p className="text-[13px] mt-3 text-center text-red-300">{error}</p>}

        <button
          type="submit"
          disabled={busy}
          className="w-full mt-5 rounded-xl font-extrabold text-[16px] disabled:opacity-50"
          style={{ background: TEAL, color: '#05070B', height: 50 }}
        >
          {busy ? t('working') : t('startPredicting')}
        </button>
      </form>
    </main>
  );
}

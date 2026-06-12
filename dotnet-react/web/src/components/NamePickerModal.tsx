import { useState } from 'react';
import { createPortal } from 'react-dom';
import { motion } from 'framer-motion';
import { useQuery } from '@tanstack/react-query';
import { matchesApi } from '../api/matches';
import { setIdentity } from '../lib/identity';
import { C } from '../lib/theme';
import { t } from '../i18n';

/**
 * Lightweight identity gate. The app has no password login, so before saving a
 * prediction the user picks their name once. On confirm we store the identity
 * and call onPicked() so the caller can proceed (e.g. complete the save).
 */
export function NamePickerModal({
  onPicked, onClose,
}: { onPicked: (id: string, name: string) => void; onClose: () => void }) {
  const players = useQuery({ queryKey: ['players'], queryFn: matchesApi.players });
  const [sel, setSel] = useState('');

  const confirm = () => {
    const p = (players.data ?? []).find((x) => x.id === sel);
    if (!p) return;
    setIdentity(p.id, p.fullName);
    onPicked(p.id, p.fullName);
  };

  return createPortal(
    <motion.div
      className="fixed inset-0 z-[70] flex items-end sm:items-center justify-center"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
    >
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onClose} />
      <motion.div
        initial={{ y: 40, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ type: 'spring', stiffness: 320, damping: 32 }}
        className="relative w-full sm:max-w-[440px] rounded-t-3xl sm:rounded-3xl border border-white/15 p-5"
        style={{ background: '#0B1118' }}
      >
        <div className="text-center mb-4">
          <div className="text-3xl mb-1">👤</div>
          <h3 className="text-lg font-extrabold">{t('whoAreYou')}</h3>
          <p className="text-[13px] text-white/55 mt-0.5">{t('pickNameToSave')}</p>
        </div>

        <select
          value={sel}
          onChange={(e) => setSel(e.target.value)}
          className="w-full rounded-xl bg-black/40 border border-white/15 px-3 py-3 text-white outline-none
                     focus:border-emerald-400 mb-4"
        >
          <option value="" disabled>
            {players.isLoading ? t('loading') : t('chooseName')}
          </option>
          {(players.data ?? []).map((p) => (
            <option key={p.id} value={p.id} className="bg-[#0B1118]">
              {p.fullName} — {p.department}
            </option>
          ))}
        </select>

        <button
          onClick={confirm}
          disabled={!sel}
          className="w-full py-3 rounded-xl font-extrabold disabled:opacity-40 disabled:cursor-not-allowed"
          style={{ background: C.primaryGreen, color: '#fff' }}
        >
          {t('confirmName')}
        </button>
      </motion.div>
    </motion.div>,
    document.body,
  );
}

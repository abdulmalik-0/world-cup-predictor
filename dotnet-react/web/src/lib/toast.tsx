import { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import { AnimatePresence, motion } from 'framer-motion';
import { C } from './theme';

export type ToastType = 'success' | 'error' | 'info';
interface Toast { id: number; msg: string; type: ToastType }

let toasts: Toast[] = [];
let listeners: Array<(t: Toast[]) => void> = [];
let seq = 0;

function emit() {
  for (const l of listeners) l(toasts);
}

/** Fire a transient toast from anywhere (no provider needed). */
export function toast(msg: string, type: ToastType = 'success', ms = 2600) {
  const id = ++seq;
  toasts = [...toasts, { id, msg, type }];
  emit();
  window.setTimeout(() => {
    toasts = toasts.filter((t) => t.id !== id);
    emit();
  }, ms);
}

const STYLE: Record<ToastType, { bg: string; icon: string }> = {
  success: { bg: C.primaryGreen, icon: '✓' },
  error:   { bg: '#B3261E',       icon: '!' },
  info:    { bg: C.blueAccent,    icon: 'i' },
};

/** Mount once near the app root. Renders the active toasts (bottom-centre). */
export function Toaster() {
  const [list, setList] = useState<Toast[]>(toasts);
  useEffect(() => {
    listeners.push(setList);
    return () => { listeners = listeners.filter((l) => l !== setList); };
  }, []);

  return createPortal(
    <div className="fixed inset-x-0 bottom-5 z-[80] flex flex-col items-center gap-2 px-4 pointer-events-none">
      <AnimatePresence>
        {list.map((t) => {
          const s = STYLE[t.type];
          return (
            <motion.div
              key={t.id}
              initial={{ opacity: 0, y: 24, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 12, scale: 0.96 }}
              transition={{ type: 'spring', stiffness: 380, damping: 30 }}
              className="pointer-events-auto flex items-center gap-2.5 max-w-[92vw] rounded-xl
                         px-4 py-3 text-white font-bold shadow-2xl"
              style={{ background: s.bg }}
            >
              <span
                className="w-5 h-5 rounded-full bg-white/25 flex items-center justify-center text-[13px] font-black shrink-0"
              >
                {s.icon}
              </span>
              <span className="text-[14px]">{t.msg}</span>
            </motion.div>
          );
        })}
      </AnimatePresence>
    </div>,
    document.body,
  );
}

import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { t } from '../i18n';

/** Handles the redirect back from Google OAuth (PKCE code exchange). */
export function AuthCallback() {
  const navigate = useNavigate();
  const { session, loading } = useAuth();

  useEffect(() => {
    if (!loading && session) {
      navigate('/dashboard', { replace: true });
    }
  }, [loading, session, navigate]);

  return (
    <main className="min-h-[100svh] flex items-center justify-center px-6">
      <div className="text-center">
        <div
          className="inline-block w-8 h-8 rounded-full border-2 border-white/30 border-t-white animate-spin mb-4"
          style={{ animationDuration: '0.7s' }}
        />
        <p className="text-white/70 font-semibold">{t('signingIn')}</p>
      </div>
    </main>
  );
}

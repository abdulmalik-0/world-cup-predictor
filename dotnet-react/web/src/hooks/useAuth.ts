import { useEffect, useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import { setIdentity, clearIdentity } from '../lib/identity';

/**
 * Tracks the Supabase auth session and keeps the app's lightweight identity
 * (eg.userId / eg.userName, used by Stats / history / the "You" highlight) in
 * sync with the logged-in user. `loading` is true until the first check resolves.
 */
export function useAuth() {
  const [session, setSession] = useState<Session | null | undefined>(undefined);

  useEffect(() => {
    let active = true;

    const cleanOAuthUrl = () => {
      const { hash, search, pathname } = window.location;
      if (hash.includes('access_token') || search.includes('code=')) {
        window.history.replaceState({}, '', pathname);
      }
    };

    supabase.auth.getSession().then(({ data }) => {
      if (!active) return;
      setSession(data.session);
      if (data.session) cleanOAuthUrl();
    });

    const { data: sub } = supabase.auth.onAuthStateChange((event, s) => {
      setSession(s);
      if (event === 'SIGNED_IN' || event === 'INITIAL_SESSION') cleanOAuthUrl();
    });

    return () => {
      active = false;
      sub.subscription.unsubscribe();
    };
  }, []);

  const uid = session?.user?.id;
  useEffect(() => {
    if (!uid) { clearIdentity(); return; }
    let active = true;
    supabase
      .from('profiles')
      .select('full_name')
      .eq('id', uid)
      .single()
      .then(({ data }) => {
        if (active) setIdentity(uid, data?.full_name ?? session?.user?.email ?? 'User');
      });
    return () => { active = false; };
  }, [uid]); // eslint-disable-line react-hooks/exhaustive-deps

  return { session, user: session?.user ?? null, loading: session === undefined };
}

import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { profileNeedsSetup, type ProfileRow } from '../lib/auth';

export function useProfile(userId: string | undefined) {
  const [profile, setProfile] = useState<ProfileRow | null | undefined>(undefined);

  const refresh = useCallback(() => {
    if (!userId) {
      setProfile(null);
      return;
    }
    setProfile(undefined);
    supabase
      .from('profiles')
      .select('id, full_name, department, avatar_url')
      .eq('id', userId)
      .single()
      .then(({ data }) => setProfile((data as ProfileRow | null) ?? null));
  }, [userId]);

  useEffect(() => { refresh(); }, [refresh]);

  return {
    profile: profile ?? null,
    loading: profile === undefined,
    needsSetup: profileNeedsSetup(profile ?? null),
    refresh,
  };
}

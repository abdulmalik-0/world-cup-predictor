import { supabase } from './supabase';

/** Where Supabase sends the browser after Google OAuth (must be allow-listed in the dashboard). */
export function authRedirectUrl(): string {
  const base = (import.meta.env.VITE_SITE_URL as string | undefined)?.replace(/\/$/, '')
    ?? window.location.origin;
  return `${base}/auth/callback`;
}

export async function signInWithGoogle() {
  return supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: authRedirectUrl(),
      queryParams: { prompt: 'select_account' },
    },
  });
}

export type ProfileRow = {
  id: string;
  full_name: string;
  department: string;
  avatar_url: string | null;
};

export function profileNeedsSetup(profile: ProfileRow | null): boolean {
  if (!profile) return true;
  return profile.full_name === 'موظف جديد' || profile.department === 'غير محدد';
}

export async function upsertProfile(fullName: string, department: string) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not signed in');

  const { data, error } = await supabase
    .from('profiles')
    .upsert({
      id: user.id,
      full_name: fullName.trim(),
      department: department.trim(),
      avatar_url: user.user_metadata?.avatar_url ?? user.user_metadata?.picture ?? null,
    })
    .select()
    .single();

  if (error) throw error;
  return data as ProfileRow;
}

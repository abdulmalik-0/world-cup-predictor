import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL as string;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

/**
 * Supabase client used for authentication and prediction writes. Predictions
 * are written through here (not the .NET API) so Postgres RLS enforces that a
 * user can only ever save their OWN pick — no impersonation possible.
 */
export const supabase = createClient(url, anonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

/** Sign out — the auth gate then shows the login screen. */
export const signOut = () => supabase.auth.signOut();

-- Admin role, in-app match management, and external result-sync support.

-- ---------------------------------------------------------------------------
-- 1) Admin flag on profiles
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;

-- Helper used by RLS. SECURITY DEFINER avoids recursive RLS on profiles.
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT is_admin FROM public.profiles WHERE id = auth.uid()),
    false
  );
$$;

-- ---------------------------------------------------------------------------
-- 2) External reference for API result sync
--    (maps a local match to a provider fixture id, e.g. football-data.org)
-- ---------------------------------------------------------------------------
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS external_ref TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_matches_external_ref
  ON public.matches(external_ref) WHERE external_ref IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3) RLS — admins can manage matches (regular users keep read-only access).
--    The existing scoring trigger is SECURITY DEFINER, so points are still
--    awarded automatically when an admin sets a final result.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS matches_admin_insert ON public.matches;
CREATE POLICY matches_admin_insert ON public.matches
  FOR INSERT TO authenticated
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS matches_admin_update ON public.matches;
CREATE POLICY matches_admin_update ON public.matches
  FOR UPDATE TO authenticated
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS matches_admin_delete ON public.matches;
CREATE POLICY matches_admin_delete ON public.matches
  FOR DELETE TO authenticated
  USING (public.is_current_user_admin());

-- ---------------------------------------------------------------------------
-- 4) Promote the first admin (run manually, replace the email):
--
--   UPDATE public.profiles SET is_admin = true
--   WHERE id = (SELECT id FROM auth.users WHERE email = 'you@company.com');
-- ---------------------------------------------------------------------------

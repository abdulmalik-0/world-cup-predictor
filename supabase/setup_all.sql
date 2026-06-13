-- ===========================================================================
-- setup_all.sql — إعداد كامل لقاعدة البيانات (الصقه مرة واحدة في Supabase SQL Editor)
-- يشمل: المخطط + الأدمن + إصلاح RLS + قفل ساعة + دبل (السعودية + الأردن)
--       + بذور مباريات الدول العربية والأدوار الإقصائية.
-- (المزامنة التلقائية 009 اختيارية — شغّلها منفصلة بعد تفعيل pg_cron/pg_net)
-- ===========================================================================

-- ===================== 001_initial_schema.sql =====================
-- Company World Cup Predictor — initial schema
-- Run via Supabase CLI or SQL Editor

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- Profiles (extends auth.users)
-- ---------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  department TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Matches
-- ---------------------------------------------------------------------------
CREATE TYPE public.match_status AS ENUM ('scheduled', 'live', 'finished', 'cancelled');

CREATE TABLE public.matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  home_team TEXT NOT NULL,
  away_team TEXT NOT NULL,
  home_team_code TEXT NOT NULL,
  away_team_code TEXT NOT NULL,
  kickoff_at TIMESTAMPTZ NOT NULL,
  home_score INT CHECK (home_score IS NULL OR home_score >= 0),
  away_score INT CHECK (away_score IS NULL OR away_score >= 0),
  is_arab_team_match BOOLEAN NOT NULL DEFAULT false,
  status public.match_status NOT NULL DEFAULT 'scheduled',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_matches_kickoff ON public.matches(kickoff_at);
CREATE INDEX idx_matches_status ON public.matches(status);

-- ---------------------------------------------------------------------------
-- Predictions
-- ---------------------------------------------------------------------------
CREATE TABLE public.predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  home_score INT NOT NULL CHECK (home_score >= 0),
  away_score INT NOT NULL CHECK (away_score >= 0),
  points_earned INT CHECK (points_earned IS NULL OR points_earned >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, match_id)
);

CREATE INDEX idx_predictions_match ON public.predictions(match_id);
CREATE INDEX idx_predictions_user ON public.predictions(user_id);

-- ---------------------------------------------------------------------------
-- Prediction edit history (transparency / taqtiqa)
-- ---------------------------------------------------------------------------
CREATE TABLE public.prediction_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID NOT NULL REFERENCES public.predictions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  old_home_score INT NOT NULL,
  old_away_score INT NOT NULL,
  new_home_score INT NOT NULL,
  new_away_score INT NOT NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_prediction_history_prediction ON public.prediction_history(prediction_id);
CREATE INDEX idx_prediction_history_match ON public.prediction_history(match_id);

-- ---------------------------------------------------------------------------
-- Helper: prediction window closes 15 minutes before kickoff
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prediction_closes_at(kickoff TIMESTAMPTZ)
RETURNS TIMESTAMPTZ
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT kickoff - INTERVAL '15 minutes';
$$;

CREATE OR REPLACE FUNCTION public.is_prediction_open(p_kickoff TIMESTAMPTZ)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT now() < public.prediction_closes_at(p_kickoff);
$$;

-- ---------------------------------------------------------------------------
-- Scoring logic (server-side)
-- Regular: exact=3, winner/draw=1, wrong=0
-- Arab match (double): exact=6, winner/draw=2
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_prediction_points(
  p_pred_home INT,
  p_pred_away INT,
  p_actual_home INT,
  p_actual_away INT,
  p_is_arab BOOLEAN
)
RETURNS INT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  base_points INT := 0;
  multiplier INT := 1;
BEGIN
  IF p_is_arab THEN
    multiplier := 2;
  END IF;

  IF p_pred_home = p_actual_home AND p_pred_away = p_actual_away THEN
    base_points := 3;
  ELSIF (p_pred_home > p_pred_away AND p_actual_home > p_actual_away)
     OR (p_pred_home < p_pred_away AND p_actual_home < p_actual_away)
     OR (p_pred_home = p_pred_away AND p_actual_home = p_actual_away) THEN
    base_points := 1;
  END IF;

  RETURN base_points * multiplier;
END;
$$;

-- ---------------------------------------------------------------------------
-- Auto-detect Arab team matches from ISO codes
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_arab_team_code(code TEXT)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT upper(trim(code)) IN (
    'SA', 'EG', 'MA', 'TN', 'DZ', 'QA', 'AE', 'JO', 'IQ', 'LB', 'SY', 'YE',
    'KW', 'BH', 'OM', 'PS', 'SD', 'LY', 'MR', 'SO', 'DJ', 'KM'
  );
$$;

CREATE OR REPLACE FUNCTION public.set_match_arab_flag()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.is_arab_team_match :=
    public.is_arab_team_code(NEW.home_team_code)
    OR public.is_arab_team_code(NEW.away_team_code);
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_matches_arab_flag
  BEFORE INSERT OR UPDATE OF home_team_code, away_team_code ON public.matches
  FOR EACH ROW EXECUTE FUNCTION public.set_match_arab_flag();

-- ---------------------------------------------------------------------------
-- Score all predictions when match result is set
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.score_match_predictions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'finished'
     AND NEW.home_score IS NOT NULL
     AND NEW.away_score IS NOT NULL
     AND (OLD.status IS DISTINCT FROM 'finished'
          OR OLD.home_score IS DISTINCT FROM NEW.home_score
          OR OLD.away_score IS DISTINCT FROM NEW.away_score) THEN

    UPDATE public.predictions p
    SET
      points_earned = public.calculate_prediction_points(
        p.home_score,
        p.away_score,
        NEW.home_score,
        NEW.away_score,
        NEW.is_arab_team_match
      ),
      updated_at = now()
    WHERE p.match_id = NEW.id;
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_score_predictions
  AFTER UPDATE OF status, home_score, away_score ON public.matches
  FOR EACH ROW EXECUTE FUNCTION public.score_match_predictions();

-- ---------------------------------------------------------------------------
-- Block predictions after lock time; log edits
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_prediction_window()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_kickoff TIMESTAMPTZ;
BEGIN
  SELECT kickoff_at INTO v_kickoff
  FROM public.matches
  WHERE id = NEW.match_id;

  IF v_kickoff IS NULL THEN
    RAISE EXCEPTION 'Match not found';
  END IF;

  IF NOT public.is_prediction_open(v_kickoff) THEN
    RAISE EXCEPTION 'Prediction window closed (15 minutes before kickoff)';
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.log_prediction_edit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.home_score IS DISTINCT FROM NEW.home_score
     OR OLD.away_score IS DISTINCT FROM NEW.away_score THEN
    INSERT INTO public.prediction_history (
      prediction_id, user_id, match_id,
      old_home_score, old_away_score,
      new_home_score, new_away_score
    ) VALUES (
      OLD.id, OLD.user_id, OLD.match_id,
      OLD.home_score, OLD.away_score,
      NEW.home_score, NEW.away_score
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_predictions_window_insert
  BEFORE INSERT ON public.predictions
  FOR EACH ROW EXECUTE FUNCTION public.enforce_prediction_window();

CREATE TRIGGER trg_predictions_window_update
  BEFORE UPDATE ON public.predictions
  FOR EACH ROW EXECUTE FUNCTION public.enforce_prediction_window();

CREATE TRIGGER trg_predictions_history
  BEFORE UPDATE ON public.predictions
  FOR EACH ROW EXECUTE FUNCTION public.log_prediction_edit();

-- ---------------------------------------------------------------------------
-- Leaderboard view
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.leaderboard AS
SELECT
  p.id AS user_id,
  p.full_name,
  p.department,
  p.avatar_url,
  COALESCE(SUM(pr.points_earned), 0)::INT AS total_points,
  COUNT(pr.id) FILTER (WHERE pr.points_earned IS NOT NULL) AS matches_scored,
  COUNT(pr.id) AS predictions_made
FROM public.profiles p
LEFT JOIN public.predictions pr ON pr.user_id = p.id
GROUP BY p.id, p.full_name, p.department, p.avatar_url
ORDER BY total_points DESC, predictions_made DESC, p.full_name ASC;

-- ---------------------------------------------------------------------------
-- Profile bootstrap on signup
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, department)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', 'موظف جديد'),
    COALESCE(NEW.raw_user_meta_data ->> 'department', 'غير محدد')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- updated_at helper
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prediction_history ENABLE ROW LEVEL SECURITY;

-- Profiles: read all authenticated; update own
CREATE POLICY profiles_select ON public.profiles
  FOR SELECT TO authenticated USING (true);

CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- Matches: read all authenticated
CREATE POLICY matches_select ON public.matches
  FOR SELECT TO authenticated USING (true);

-- Predictions: read own always; read others only after prediction window closes
CREATE POLICY predictions_select_own ON public.predictions
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY predictions_select_others_after_lock ON public.predictions
  FOR SELECT TO authenticated
  USING (
    auth.uid() <> user_id
    AND EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = match_id
        AND NOT public.is_prediction_open(m.kickoff_at)
    )
  );

CREATE POLICY predictions_insert_own ON public.predictions
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY predictions_update_own ON public.predictions
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- History: visible after prediction window closes for that match
CREATE POLICY prediction_history_select ON public.prediction_history
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = match_id
        AND NOT public.is_prediction_open(m.kickoff_at)
    )
  );

-- Leaderboard view inherits profiles RLS via security invoker; grant select
GRANT SELECT ON public.leaderboard TO authenticated;

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.predictions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- ===================== 002_team_names_en.sql =====================
-- Add English team names for bilingual display

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS home_team_en TEXT,
  ADD COLUMN IF NOT EXISTS away_team_en TEXT;

-- Backfill from codes where possible (optional — seed.sql replaces data)

-- ===================== 003_admin_and_sync.sql =====================
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

-- ===================== 004_fix_prediction_history_rls.sql =====================
-- Fix: editing a prediction failed with an RLS error.
--
-- The BEFORE UPDATE trigger `log_prediction_edit` inserts a row into
-- `prediction_history`, but that table had only a SELECT policy — so the
-- trigger's INSERT was denied by RLS and the whole UPDATE (the edit) failed.
-- First-time predictions worked because the trigger only runs on UPDATE.
--
-- Allow authenticated users to insert their own history rows.

DROP POLICY IF EXISTS prediction_history_insert ON public.prediction_history;
CREATE POLICY prediction_history_insert ON public.prediction_history
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- ===================== 005_reset_match_scores.sql =====================
-- Clear prediction points when admin resets a match back to scheduled.

CREATE OR REPLACE FUNCTION public.score_match_predictions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Admin reset: finished → scheduled (or any non-finished) clears awarded points.
  IF OLD.status = 'finished'
     AND NEW.status IS DISTINCT FROM 'finished' THEN
    UPDATE public.predictions p
    SET points_earned = NULL, updated_at = now()
    WHERE p.match_id = NEW.id;
  END IF;

  IF NEW.status = 'finished'
     AND NEW.home_score IS NOT NULL
     AND NEW.away_score IS NOT NULL
     AND (OLD.status IS DISTINCT FROM 'finished'
          OR OLD.home_score IS DISTINCT FROM NEW.home_score
          OR OLD.away_score IS DISTINCT FROM NEW.away_score) THEN

    UPDATE public.predictions p
    SET
      points_earned = public.calculate_prediction_points(
        p.home_score,
        p.away_score,
        NEW.home_score,
        NEW.away_score,
        NEW.is_arab_team_match
      ),
      updated_at = now()
    WHERE p.match_id = NEW.id;
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- ===================== 007_leaderboard_accuracy.sql =====================
-- Leaderboard: add correct-outcome and exact-score counts for percentages.

CREATE OR REPLACE VIEW public.leaderboard AS
SELECT
  p.id AS user_id,
  p.full_name,
  p.department,
  p.avatar_url,
  COALESCE(SUM(pr.points_earned), 0)::INT AS total_points,
  COUNT(pr.id) FILTER (WHERE pr.points_earned IS NOT NULL) AS matches_scored,
  COUNT(pr.id) AS predictions_made,
  COUNT(pr.id) FILTER (
    WHERE m.status = 'finished'
      AND m.home_score IS NOT NULL
      AND m.away_score IS NOT NULL
  ) AS finished_predictions,
  COUNT(pr.id) FILTER (
    WHERE m.status = 'finished'
      AND m.home_score IS NOT NULL
      AND m.away_score IS NOT NULL
      AND COALESCE(pr.points_earned, 0) > 0
  ) AS correct_predictions,
  COUNT(pr.id) FILTER (
    WHERE m.status = 'finished'
      AND m.home_score IS NOT NULL
      AND m.away_score IS NOT NULL
      AND pr.home_score = m.home_score
      AND pr.away_score = m.away_score
  ) AS exact_predictions
FROM public.profiles p
LEFT JOIN public.predictions pr ON pr.user_id = p.id
LEFT JOIN public.matches m ON m.id = pr.match_id
GROUP BY p.id, p.full_name, p.department, p.avatar_url
ORDER BY total_points DESC, predictions_made DESC, p.full_name ASC;

-- ===================== 008_prediction_lock_1h.sql =====================
-- Close predictions 1 hour before kickoff (was 15 minutes).

CREATE OR REPLACE FUNCTION public.prediction_closes_at(kickoff TIMESTAMPTZ)
RETURNS TIMESTAMPTZ
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT kickoff - INTERVAL '1 hour';
$$;

CREATE OR REPLACE FUNCTION public.enforce_prediction_window()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_kickoff TIMESTAMPTZ;
BEGIN
  SELECT kickoff_at INTO v_kickoff
  FROM public.matches
  WHERE id = NEW.match_id;

  IF v_kickoff IS NULL THEN
    RAISE EXCEPTION 'Match not found';
  END IF;

  IF NOT public.is_prediction_open(v_kickoff) THEN
    RAISE EXCEPTION 'Prediction window closed (1 hour before kickoff)';
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- ===================== 010_jordan_saudi_double_points.sql =====================
-- ===========================================================================
-- 010 — Double points for Saudi Arabia (SA) AND Jordan (JO).
-- ===========================================================================
-- The column `matches.is_arab_team_match` is reused as the "double points"
-- flag (kept for backward compatibility). A match qualifies for double points
-- when either team is Saudi Arabia OR Jordan.
--
-- Scoring (server-side, see calculate_prediction_points):
--   Regular match : exact = 3 , winner/draw = 1
--   Double  match : exact = 6 , winner/draw = 2   (SA or JO)
-- ===========================================================================

-- 1) Which national-team codes earn double points.
CREATE OR REPLACE FUNCTION public.is_arab_team_code(code TEXT)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT upper(trim(code)) IN ('SA', 'JO');
$$;

-- 2) Re-apply the flag to every existing match using the new rule.
--    (The BEFORE-trigger trg_matches_arab_flag keeps it correct for future rows.)
UPDATE public.matches m
SET is_arab_team_match =
      public.is_arab_team_code(m.home_team_code)
   OR public.is_arab_team_code(m.away_team_code);

-- 3) Recalculate points for already-finished matches so the leaderboard
--    reflects the new double-points rule immediately.
UPDATE public.predictions p
SET
  points_earned = public.calculate_prediction_points(
    p.home_score,
    p.away_score,
    m.home_score,
    m.away_score,
    m.is_arab_team_match
  ),
  updated_at = now()
FROM public.matches m
WHERE p.match_id = m.id
  AND m.status = 'finished'
  AND m.home_score IS NOT NULL
  AND m.away_score IS NOT NULL;

-- ===================== seed.sql =====================
-- ===========================================================================
-- كأس العالم 2026 — مباريات الدول العربية + الأدوار الإقصائية
-- التوقيت: بتوقيت السعودية (+03)
-- ---------------------------------------------------------------------------
-- الدول العربية المشاركة: السعودية، الأردن، المغرب، تونس، مصر، الجزائر،
--                          العراق، قطر.
-- 🔥 دبل النقاط (×2) على: السعودية (SA) والأردن (JO).
--    (يُحسب تلقائياً عبر دالة is_arab_team_code — راجع migration 010)
-- ===========================================================================

TRUNCATE public.prediction_history, public.predictions, public.matches CASCADE;

-- ---------------------------------------------------------------------------
-- 1) دور المجموعات — مباريات الدول العربية فقط
-- ---------------------------------------------------------------------------
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  -- الجولة الأولى
  ('قطر', 'Qatar', 'سويسرا', 'Switzerland', 'QA', 'CH', '2026-06-13 22:00:00+03', 'scheduled'),
  ('البرازيل', 'Brazil', 'المغرب', 'Morocco', 'BR', 'MA', '2026-06-14 01:00:00+03', 'scheduled'),
  ('السويد', 'Sweden', 'تونس', 'Tunisia', 'SE', 'TN', '2026-06-15 05:00:00+03', 'scheduled'),
  ('بلجيكا', 'Belgium', 'مصر', 'Egypt', 'BE', 'EG', '2026-06-15 22:00:00+03', 'scheduled'),
  ('أوروغواي', 'Uruguay', 'السعودية', 'Saudi Arabia', 'UY', 'SA', '2026-06-16 01:00:00+03', 'scheduled'),  -- 🔥 دبل
  ('العراق', 'Iraq', 'النرويج', 'Norway', 'IQ', 'NO', '2026-06-17 01:00:00+03', 'scheduled'),
  ('الأرجنتين', 'Argentina', 'الجزائر', 'Algeria', 'AR', 'DZ', '2026-06-17 04:00:00+03', 'scheduled'),
  ('النمسا', 'Austria', 'الأردن', 'Jordan', 'AT', 'JO', '2026-06-17 07:00:00+03', 'scheduled'),         -- 🔥 دبل

  -- الجولة الثانية
  ('كندا', 'Canada', 'قطر', 'Qatar', 'CA', 'QA', '2026-06-19 01:00:00+03', 'scheduled'),
  ('اسكتلندا', 'Scotland', 'المغرب', 'Morocco', 'SF', 'MA', '2026-06-20 01:00:00+03', 'scheduled'),
  ('تونس', 'Tunisia', 'اليابان', 'Japan', 'TN', 'JP', '2026-06-21 07:00:00+03', 'scheduled'),
  ('إسبانيا', 'Spain', 'السعودية', 'Saudi Arabia', 'ES', 'SA', '2026-06-21 19:00:00+03', 'scheduled'),    -- 🔥 دبل
  ('نيوزيلندا', 'New Zealand', 'مصر', 'Egypt', 'NZ', 'EG', '2026-06-22 04:00:00+03', 'scheduled'),
  ('فرنسا', 'France', 'العراق', 'Iraq', 'FR', 'IQ', '2026-06-23 01:00:00+03', 'scheduled'),
  ('الأردن', 'Jordan', 'الجزائر', 'Algeria', 'JO', 'DZ', '2026-06-23 07:00:00+03', 'scheduled'),         -- 🔥 دبل

  -- الجولة الثالثة
  ('المغرب', 'Morocco', 'هايتي', 'Haiti', 'MA', 'HT', '2026-06-24 22:00:00+03', 'scheduled'),
  ('البوسنة والهرسك', 'Bosnia', 'قطر', 'Qatar', 'BA', 'QA', '2026-06-25 01:00:00+03', 'scheduled'),
  ('تونس', 'Tunisia', 'هولندا', 'Netherlands', 'TN', 'NL', '2026-06-25 23:00:00+03', 'scheduled'),
  ('الرأس الأخضر', 'Cape Verde', 'السعودية', 'Saudi Arabia', 'CV', 'SA', '2026-06-26 19:00:00+03', 'scheduled'),  -- 🔥 دبل
  ('مصر', 'Egypt', 'إيران', 'Iran', 'EG', 'IR', '2026-06-26 22:00:00+03', 'scheduled'),
  ('السنغال', 'Senegal', 'العراق', 'Iraq', 'SN', 'IQ', '2026-06-27 01:00:00+03', 'scheduled'),
  ('الجزائر', 'Algeria', 'النمسا', 'Austria', 'DZ', 'AT', '2026-06-27 04:00:00+03', 'scheduled'),
  ('الأرجنتين', 'Argentina', 'الأردن', 'Jordan', 'AR', 'JO', '2026-06-27 04:00:00+03', 'scheduled');     -- 🔥 دبل

-- ---------------------------------------------------------------------------
-- 2) الأدوار الإقصائية — الفرق تُحدَّد لاحقاً (TBD) من لوحة التحكم
--    عند إدخال السعودية (SA) أو الأردن (JO) في أي مباراة، يُفعَّل الدبل تلقائياً.
-- ---------------------------------------------------------------------------

-- دور الـ32
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('دور الـ32 — مباراة 1',  'Round of 32 — M1',  'TBD', 'TBD', 'XX', 'YY', '2026-06-28 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 2',  'Round of 32 — M2',  'TBD', 'TBD', 'XX', 'YY', '2026-06-28 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 3',  'Round of 32 — M3',  'TBD', 'TBD', 'XX', 'YY', '2026-06-29 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 4',  'Round of 32 — M4',  'TBD', 'TBD', 'XX', 'YY', '2026-06-29 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 5',  'Round of 32 — M5',  'TBD', 'TBD', 'XX', 'YY', '2026-06-30 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 6',  'Round of 32 — M6',  'TBD', 'TBD', 'XX', 'YY', '2026-06-30 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 7',  'Round of 32 — M7',  'TBD', 'TBD', 'XX', 'YY', '2026-07-01 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 8',  'Round of 32 — M8',  'TBD', 'TBD', 'XX', 'YY', '2026-07-01 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 9',  'Round of 32 — M9',  'TBD', 'TBD', 'XX', 'YY', '2026-07-02 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 10', 'Round of 32 — M10', 'TBD', 'TBD', 'XX', 'YY', '2026-07-02 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 11', 'Round of 32 — M11', 'TBD', 'TBD', 'XX', 'YY', '2026-07-03 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 12', 'Round of 32 — M12', 'TBD', 'TBD', 'XX', 'YY', '2026-07-03 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 13', 'Round of 32 — M13', 'TBD', 'TBD', 'XX', 'YY', '2026-07-04 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 14', 'Round of 32 — M14', 'TBD', 'TBD', 'XX', 'YY', '2026-07-04 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 15', 'Round of 32 — M15', 'TBD', 'TBD', 'XX', 'YY', '2026-07-05 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 16', 'Round of 32 — M16', 'TBD', 'TBD', 'XX', 'YY', '2026-07-05 23:00:00+03', 'scheduled');

-- دور الـ16
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('دور الـ16 — مباراة 1', 'Round of 16 — M1', 'TBD', 'TBD', 'XX', 'YY', '2026-07-06 19:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 2', 'Round of 16 — M2', 'TBD', 'TBD', 'XX', 'YY', '2026-07-06 23:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 3', 'Round of 16 — M3', 'TBD', 'TBD', 'XX', 'YY', '2026-07-07 19:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 4', 'Round of 16 — M4', 'TBD', 'TBD', 'XX', 'YY', '2026-07-07 23:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 5', 'Round of 16 — M5', 'TBD', 'TBD', 'XX', 'YY', '2026-07-08 19:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 6', 'Round of 16 — M6', 'TBD', 'TBD', 'XX', 'YY', '2026-07-08 23:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 7', 'Round of 16 — M7', 'TBD', 'TBD', 'XX', 'YY', '2026-07-09 19:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 8', 'Round of 16 — M8', 'TBD', 'TBD', 'XX', 'YY', '2026-07-09 23:00:00+03', 'scheduled');

-- ربع النهائي
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('ربع النهائي 1', 'Quarter-Final 1', 'TBD', 'TBD', 'XX', 'YY', '2026-07-11 19:00:00+03', 'scheduled'),
  ('ربع النهائي 2', 'Quarter-Final 2', 'TBD', 'TBD', 'XX', 'YY', '2026-07-11 23:00:00+03', 'scheduled'),
  ('ربع النهائي 3', 'Quarter-Final 3', 'TBD', 'TBD', 'XX', 'YY', '2026-07-12 19:00:00+03', 'scheduled'),
  ('ربع النهائي 4', 'Quarter-Final 4', 'TBD', 'TBD', 'XX', 'YY', '2026-07-12 23:00:00+03', 'scheduled');

-- نصف النهائي
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('نصف النهائي 1', 'Semi-Final 1', 'TBD', 'TBD', 'XX', 'YY', '2026-07-14 22:00:00+03', 'scheduled'),
  ('نصف النهائي 2', 'Semi-Final 2', 'TBD', 'TBD', 'XX', 'YY', '2026-07-15 22:00:00+03', 'scheduled');

-- تحديد المركز الثالث + النهائي
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('تحديد المركز الثالث', 'Third Place', 'TBD', 'TBD', 'XX', 'YY', '2026-07-18 23:00:00+03', 'scheduled'),
  ('النهائي', 'Final', 'TBD', 'TBD', 'XX', 'YY', '2026-07-19 22:00:00+03', 'scheduled');


-- ===================== 011_saudi_only_double_points.sql =====================
-- ===========================================================================
-- 011 — Double points for Saudi Arabia (SA) ONLY (reverts 010's SA+JO).
-- ===========================================================================
-- A match earns double points (exact = 6, winner/draw = 2) only when Saudi
-- Arabia plays in it. The column matches.is_arab_team_match is reused as the
-- "double points" flag.
-- ===========================================================================

-- 1) Only Saudi Arabia earns double points.
CREATE OR REPLACE FUNCTION public.is_arab_team_code(code TEXT)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT upper(trim(code)) = 'SA';
$$;

-- 2) Re-apply the flag to every match using the new rule.
UPDATE public.matches m
SET is_arab_team_match =
      public.is_arab_team_code(m.home_team_code)
   OR public.is_arab_team_code(m.away_team_code);

-- 3) Recalculate points for already-finished matches.
UPDATE public.predictions p
SET
  points_earned = public.calculate_prediction_points(
    p.home_score,
    p.away_score,
    m.home_score,
    m.away_score,
    m.is_arab_team_match
  ),
  updated_at = now()
FROM public.matches m
WHERE p.match_id = m.id
  AND m.status = 'finished'
  AND m.home_score IS NOT NULL
  AND m.away_score IS NOT NULL;

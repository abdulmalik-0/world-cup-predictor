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

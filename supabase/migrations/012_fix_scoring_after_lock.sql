-- Fix: allow the server to score predictions after the lock window.
--
-- Bug: enforce_prediction_window() blocked EVERY prediction UPDATE once the
-- window closed. The scoring trigger (score_match_predictions) updates
-- predictions.points_earned when a match finishes (which happens AFTER the
-- window closes), so any match that had predictions could never be scored,
-- by the API sync OR by manual admin entry: the whole match UPDATE rolled
-- back with 'Prediction window closed'.
--
-- Now the window is enforced only when the USER actually changes their pick
-- (home_score/away_score). System updates that touch only points_earned pass.

CREATE OR REPLACE FUNCTION public.enforce_prediction_window()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_kickoff TIMESTAMPTZ;
BEGIN
  -- Allow system updates that do not change the pick itself (e.g. scoring).
  IF TG_OP = 'UPDATE'
     AND NEW.home_score IS NOT DISTINCT FROM OLD.home_score
     AND NEW.away_score IS NOT DISTINCT FROM OLD.away_score THEN
    RETURN NEW;
  END IF;

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

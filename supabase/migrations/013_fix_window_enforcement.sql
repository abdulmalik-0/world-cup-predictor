-- ===========================================================================
-- 013 — Don't enforce the prediction window for SERVER-side updates.
-- ===========================================================================
-- When sync-results-espn updates a finished match's score, the trigger
-- `score_match_predictions` cascades an UPDATE into `predictions` setting
-- `points_earned`. That UPDATE then fires `enforce_prediction_window`, which
-- raises "Prediction window closed" because kickoff is now in the past.
--
-- The fix: the window enforcement should only block when the user actually
-- changes their pick (`home_score` / `away_score`). Server-side updates that
-- only change `points_earned` (and `updated_at`) are allowed through.
-- ===========================================================================

CREATE OR REPLACE FUNCTION public.enforce_prediction_window()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_kickoff TIMESTAMPTZ;
BEGIN
  -- On UPDATE: if the user's pick (home_score/away_score) hasn't changed,
  -- this is a server-driven update (e.g. points_earned recalculation) and
  -- we let it through unconditionally.
  IF TG_OP = 'UPDATE'
     AND NEW.home_score IS NOT DISTINCT FROM OLD.home_score
     AND NEW.away_score IS NOT DISTINCT FROM OLD.away_score THEN
    NEW.updated_at := now();
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

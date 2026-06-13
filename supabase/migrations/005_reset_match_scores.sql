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

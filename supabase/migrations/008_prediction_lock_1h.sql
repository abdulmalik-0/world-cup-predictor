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

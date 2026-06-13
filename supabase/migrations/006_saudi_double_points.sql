-- Restrict double points to Saudi Arabia (SA) matches only.
-- Column name is_arab_team_match is kept for compatibility.

CREATE OR REPLACE FUNCTION public.is_arab_team_code(code TEXT)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT upper(trim(code)) = 'SA';
$$;

UPDATE public.matches m
SET is_arab_team_match =
  public.is_arab_team_code(m.home_team_code)
  OR public.is_arab_team_code(m.away_team_code);

-- Recalculate points for finished matches if flags changed.
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

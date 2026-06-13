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

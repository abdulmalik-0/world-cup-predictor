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

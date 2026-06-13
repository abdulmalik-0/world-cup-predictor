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

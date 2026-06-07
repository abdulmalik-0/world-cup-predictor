-- Sample matches for development / demo
-- Adjust kickoff times relative to now()

INSERT INTO public.matches (home_team, away_team, home_team_code, away_team_code, kickoff_at, status)
VALUES
  ('السعودية', 'الأرجنتين', 'SA', 'AR', now() + INTERVAL '3 days', 'scheduled'),
  ('مصر', 'إنجلترا', 'EG', 'GB', now() + INTERVAL '4 days', 'scheduled'),
  ('فرنسا', 'ألمانيا', 'FR', 'DE', now() + INTERVAL '5 days', 'scheduled'),
  ('المغرب', 'إسبانيا', 'MA', 'ES', now() + INTERVAL '6 days', 'scheduled'),
  ('البرازيل', 'البرتغال', 'BR', 'PT', now() + INTERVAL '7 days', 'scheduled');

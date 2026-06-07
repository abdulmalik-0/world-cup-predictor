-- Add English team names for bilingual display

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS home_team_en TEXT,
  ADD COLUMN IF NOT EXISTS away_team_en TEXT;

-- Backfill from codes where possible (optional — seed.sql replaces data)

-- ===========================================================================
-- 012 — Schedule the ESPN sync function every 10 minutes (pg_cron + pg_net).
-- ===========================================================================
-- BEFORE running this migration:
--   1) Dashboard → Database → Extensions → enable "pg_cron" and "pg_net".
--   2) Replace the placeholders below with your real values:
--        - <PROJECT_REF>  e.g. qzpherhhmwlvrtlgsfxe
--        - <ANON_KEY>     anon public key from Settings → API
--
-- To remove the schedule later:
--   SELECT cron.unschedule('sync-wc-results-espn-every-10m');
-- ===========================================================================

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Remove any previous schedule with the same name.
DO $$
BEGIN
  PERFORM cron.unschedule(jobid)
  FROM cron.job
  WHERE jobname = 'sync-wc-results-espn-every-10m';
EXCEPTION
  WHEN undefined_table THEN NULL;
END $$;

SELECT cron.schedule(
  'sync-wc-results-espn-every-10m',
  '*/10 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/sync-results-espn',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <ANON_KEY>'
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);

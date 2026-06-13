-- Schedule sync-results every 10 minutes (Supabase: pg_cron + pg_net).
--
-- BEFORE running:
-- 1) Dashboard -> Database -> Extensions -> enable "pg_cron" and "pg_net"
-- 2) Replace YOUR_ANON_KEY below with the anon key from env.json
--    (Project Settings -> API -> anon public)
--
-- Run once in SQL Editor. To remove later:
--   SELECT cron.unschedule('sync-wc-results-every-10m');

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

DO $$
BEGIN
  PERFORM cron.unschedule(jobid)
  FROM cron.job
  WHERE jobname = 'sync-wc-results-every-10m';
EXCEPTION
  WHEN undefined_table THEN NULL;
END $$;

SELECT cron.schedule(
  'sync-wc-results-every-10m',
  '*/10 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://pwojrsmbgdtzmoqzwusy.supabase.co/functions/v1/sync-results',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_ANON_KEY'
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);

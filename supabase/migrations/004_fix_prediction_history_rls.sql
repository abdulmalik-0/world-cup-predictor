-- Fix: editing a prediction failed with an RLS error.
--
-- The BEFORE UPDATE trigger `log_prediction_edit` inserts a row into
-- `prediction_history`, but that table had only a SELECT policy — so the
-- trigger's INSERT was denied by RLS and the whole UPDATE (the edit) failed.
-- First-time predictions worked because the trigger only runs on UPDATE.
--
-- Allow authenticated users to insert their own history rows.

DROP POLICY IF EXISTS prediction_history_insert ON public.prediction_history;
CREATE POLICY prediction_history_insert ON public.prediction_history
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

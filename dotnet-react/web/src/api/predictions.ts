import { supabase } from '../lib/supabase';
import type { Prediction } from './types';

interface Row {
  id: string;
  user_id: string;
  match_id: string;
  home_score: number;
  away_score: number;
  points_earned: number | null;
}

const map = (r: Row): Prediction => ({
  id: r.id,
  userId: r.user_id,
  matchId: r.match_id,
  homeScore: r.home_score,
  awayScore: r.away_score,
  pointsEarned: r.points_earned,
});

/**
 * Save / update the CURRENT user's prediction. Written through Supabase so RLS
 * (auth.uid() = user_id) guarantees you can only ever save your own pick. Empty
 * scores default to 0-0. Throws with a recognisable message on a closed window.
 */
export async function savePick(matchId: string, home: number, away: number): Promise<void> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('not_authenticated');

  const { error } = await supabase
    .from('predictions')
    .upsert(
      { user_id: user.id, match_id: matchId, home_score: home ?? 0, away_score: away ?? 0 },
      { onConflict: 'user_id,match_id' },
    );
  if (error) throw error;
}

/** The current user's own predictions (RLS returns only theirs). */
export async function myPicks(): Promise<Prediction[]> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];
  const { data, error } = await supabase
    .from('predictions')
    .select('id, user_id, match_id, home_score, away_score, points_earned')
    .eq('user_id', user.id);
  if (error) throw error;
  return (data as Row[]).map(map);
}

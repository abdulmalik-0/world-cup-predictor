import { supabase } from '../lib/supabase';
import type {
  LeaderboardEntry, Match, MatchPicksResponse, Player, Prediction, UserPick,
} from './types';

type MatchRow = {
  id: string;
  home_team: string;
  home_team_en: string | null;
  away_team: string;
  away_team_en: string | null;
  home_team_code: string;
  away_team_code: string;
  kickoff_at: string;
  home_score: number | null;
  away_score: number | null;
  is_arab_team_match: boolean;
  status: Match['status'];
};

type LeaderboardRow = {
  user_id: string;
  full_name: string;
  department: string;
  total_points: number;
  predictions_made: number;
  finished_predictions: number;
  correct_predictions: number;
  exact_predictions: number;
};

const mapMatch = (r: MatchRow): Match => ({
  id: r.id,
  homeTeam: r.home_team,
  homeTeamEn: r.home_team_en,
  awayTeam: r.away_team,
  awayTeamEn: r.away_team_en,
  homeTeamCode: r.home_team_code,
  awayTeamCode: r.away_team_code,
  kickoffAt: r.kickoff_at,
  homeScore: r.home_score,
  awayScore: r.away_score,
  isArabTeamMatch: r.is_arab_team_match,
  status: r.status,
});

const mapLeaderboard = (r: LeaderboardRow): LeaderboardEntry => ({
  userId: r.user_id,
  fullName: r.full_name,
  department: r.department,
  totalPoints: r.total_points,
  predictionsMade: r.predictions_made,
  finishedPredictions: r.finished_predictions,
  correctPredictions: r.correct_predictions,
  exactPredictions: r.exact_predictions,
});

const MATCH_COLS =
  'id, home_team, home_team_en, away_team, away_team_en, home_team_code, away_team_code, kickoff_at, home_score, away_score, is_arab_team_match, status';

function isLocked(kickoffIso: string): boolean {
  return Date.now() >= new Date(kickoffIso).getTime() - 60 * 60 * 1000;
}

type ProfileJoin = { full_name: string; department: string };

function profileFromJoin(profile: ProfileJoin | ProfileJoin[] | null | undefined): ProfileJoin {
  if (Array.isArray(profile)) return profile[0] ?? { full_name: '', department: '' };
  return profile ?? { full_name: '', department: '' };
}

async function fetchMatches(filter?: { upcoming?: boolean; finished?: boolean }): Promise<Match[]> {
  let q = supabase.from('matches').select(MATCH_COLS);
  if (filter?.upcoming) {
    q = q.in('status', ['scheduled', 'live']).order('kickoff_at', { ascending: true });
  } else if (filter?.finished) {
    q = q.eq('status', 'finished').order('kickoff_at', { ascending: false });
  } else {
    q = q.order('kickoff_at', { ascending: true });
  }
  const { data, error } = await q;
  if (error) throw error;
  return (data as MatchRow[]).map(mapMatch);
}

export const matchesApi = {
  upcoming: () => fetchMatches({ upcoming: true }),
  finished: () => fetchMatches({ finished: true }),
  all:         () => fetchMatches(),

  playerHistory: async (userId: string): Promise<UserPick[]> => {
    const cutoff = new Date(Date.now() + 60 * 60 * 1000).toISOString();
    const { data, error } = await supabase
      .from('predictions')
      .select(`
        home_score, away_score, points_earned,
        match:matches!inner (
          id, home_team, home_team_en, home_team_code,
          away_team, away_team_en, away_team_code,
          kickoff_at, status, home_score, away_score
        )
      `)
      .eq('user_id', userId)
      .lte('match.kickoff_at', cutoff)
      .order('kickoff_at', { foreignTable: 'matches', ascending: false });
    if (error) throw error;

    return (data ?? []).map((row) => {
      const m = row.match as unknown as MatchRow;
      return {
        matchId: m.id,
        homeTeam: m.home_team,
        homeTeamEn: m.home_team_en,
        homeTeamCode: m.home_team_code,
        awayTeam: m.away_team,
        awayTeamEn: m.away_team_en,
        awayTeamCode: m.away_team_code,
        kickoffAt: m.kickoff_at,
        status: m.status,
        homeScore: m.home_score,
        awayScore: m.away_score,
        predHome: row.home_score,
        predAway: row.away_score,
        pointsEarned: row.points_earned,
      };
    });
  },

  myPicks: async (userId: string): Promise<Prediction[]> => {
    const { data, error } = await supabase
      .from('predictions')
      .select('id, user_id, match_id, home_score, away_score, points_earned')
      .eq('user_id', userId);
    if (error) throw error;
    return (data ?? []).map((r) => ({
      id: r.id,
      userId: r.user_id,
      matchId: r.match_id,
      homeScore: r.home_score,
      awayScore: r.away_score,
      pointsEarned: r.points_earned,
    }));
  },

  savePick: async (_matchId: string, _userId: string, _home: number, _away: number) => {
    throw new Error('use predictions.savePick');
  },

  matchPicks: async (matchId: string): Promise<MatchPicksResponse> => {
    const { data: match, error: matchErr } = await supabase
      .from('matches')
      .select('kickoff_at, status')
      .eq('id', matchId)
      .single();
    if (matchErr) throw matchErr;

    const locked = isLocked(match.kickoff_at);
    if (!locked) {
      return { locked: false, finished: false, predictions: [] };
    }

    const { data, error } = await supabase
      .from('predictions')
      .select('home_score, away_score, points_earned, user_id, profile:profiles!inner(full_name, department)')
      .eq('match_id', matchId);
    if (error) throw error;

    const predictions = (data ?? [])
      .map((r) => {
        const profile = profileFromJoin(r.profile as ProfileJoin | ProfileJoin[] | null);
        return {
          userId: r.user_id,
          fullName: profile.full_name,
          department: profile.department,
          homeScore: r.home_score,
          awayScore: r.away_score,
          pointsEarned: r.points_earned,
        };
      })
      .sort((a, b) => (b.pointsEarned ?? -1) - (a.pointsEarned ?? -1) || a.fullName.localeCompare(b.fullName));

    return {
      locked: true,
      finished: match.status === 'finished',
      predictions,
    };
  },

  leaderboard: async (): Promise<LeaderboardEntry[]> => {
    const { data, error } = await supabase
      .from('leaderboard')
      .select('user_id, full_name, department, total_points, predictions_made, finished_predictions, correct_predictions, exact_predictions')
      .order('total_points', { ascending: false })
      .order('exact_predictions', { ascending: false })
      .order('correct_predictions', { ascending: false });
    if (error) throw error;
    return (data as LeaderboardRow[]).map(mapLeaderboard);
  },

  playerStats: async (userId: string): Promise<LeaderboardEntry> => {
    const { data, error } = await supabase
      .from('leaderboard')
      .select('user_id, full_name, department, total_points, predictions_made, finished_predictions, correct_predictions, exact_predictions')
      .eq('user_id', userId)
      .single();
    if (error) throw error;
    return mapLeaderboard(data as LeaderboardRow);
  },

  players: async (): Promise<Player[]> => {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, full_name, department')
      .order('full_name');
    if (error) throw error;
    return (data ?? []).map((r) => ({
      id: r.id,
      fullName: r.full_name,
      department: r.department,
    }));
  },
};

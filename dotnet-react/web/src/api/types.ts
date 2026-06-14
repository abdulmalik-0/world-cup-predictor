export type MatchStatus = 'scheduled' | 'live' | 'finished' | 'cancelled';

export interface Match {
  id: string;
  homeTeam: string;
  homeTeamEn: string | null;
  awayTeam: string;
  awayTeamEn: string | null;
  homeTeamCode: string;
  awayTeamCode: string;
  kickoffAt: string;
  homeScore: number | null;
  awayScore: number | null;
  isArabTeamMatch: boolean;
  status: MatchStatus;
}

export interface Prediction {
  id: string;
  userId: string;
  matchId: string;
  homeScore: number;
  awayScore: number;
  pointsEarned: number | null;
}

export interface LeaderboardEntry {
  userId: string;
  fullName: string;
  department: string;
  totalPoints: number;
  predictionsMade: number;
  finishedPredictions: number;
  correctPredictions: number;
  exactPredictions: number;
}

export interface Player {
  id: string;
  fullName: string;
  department: string;
}

export interface MatchPick {
  userId: string;
  fullName: string;
  department: string;
  homeScore: number;
  awayScore: number;
  pointsEarned: number | null;
}

export interface MatchPicksResponse {
  locked: boolean;
  finished: boolean;
  predictions: MatchPick[];
}

/** One row of a user's prediction history (match + their pick + result). */
export interface UserPick {
  matchId: string;
  homeTeam: string;
  homeTeamEn: string | null;
  homeTeamCode: string;
  awayTeam: string;
  awayTeamEn: string | null;
  awayTeamCode: string;
  kickoffAt: string;
  status: MatchStatus;
  homeScore: number | null;
  awayScore: number | null;
  predHome: number;
  predAway: number;
  pointsEarned: number | null;
}

export interface AuthResponse {
  token: string;
  userId: string;
  fullName: string;
  isAdmin: boolean;
}

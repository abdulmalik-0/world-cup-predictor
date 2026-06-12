import { api } from './client';
import type { LeaderboardEntry, Match, Prediction } from './types';

export const matchesApi = {
  upcoming:    () => api.get<Match[]>('/matches/upcoming').then(r => r.data),
  all:         () => api.get<Match[]>('/matches').then(r => r.data),
  myPicks:     () => api.get<Prediction[]>('/predictions/mine').then(r => r.data),
  savePick:    (matchId: string, home: number, away: number) =>
                 api.put<Prediction>(`/predictions/${matchId}`, { homeScore: home, awayScore: away }).then(r => r.data),
  leaderboard: () => api.get<LeaderboardEntry[]>('/leaderboard').then(r => r.data),
};

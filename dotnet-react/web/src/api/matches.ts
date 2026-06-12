import { api } from './client';
import type { LeaderboardEntry, Match, MatchPicksResponse, Player, Prediction } from './types';

export const matchesApi = {
  upcoming:    () => api.get<Match[]>('/matches/upcoming').then(r => r.data),
  all:         () => api.get<Match[]>('/matches').then(r => r.data),
  myPicks:     () => api.get<Prediction[]>('/predictions/mine').then(r => r.data),
  savePick:    (matchId: string, home: number, away: number) =>
                 api.put<Prediction>(`/predictions/${matchId}`, { homeScore: home, awayScore: away }).then(r => r.data),
  matchPicks:  (matchId: string) =>
                 api.get<MatchPicksResponse>(`/matches/${matchId}/predictions`).then(r => r.data),
  leaderboard: () => api.get<LeaderboardEntry[]>('/leaderboard').then(r => r.data),
  playerStats: (userId: string) =>
                 api.get<LeaderboardEntry>(`/leaderboard/${userId}`).then(r => r.data),
  players:     () => api.get<Player[]>('/players').then(r => r.data),
};

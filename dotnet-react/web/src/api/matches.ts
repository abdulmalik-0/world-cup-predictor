import { api } from './client';
import type {
  LeaderboardEntry, Match, MatchPicksResponse, Player, Prediction, UserPick,
} from './types';

export const matchesApi = {
  upcoming:    () => api.get<Match[]>('/matches/upcoming').then(r => r.data),
  finished:    () => api.get<Match[]>('/matches/finished').then(r => r.data),
  all:         () => api.get<Match[]>('/matches').then(r => r.data),
  playerHistory: (userId: string) =>
                 api.get<UserPick[]>(`/players/${userId}/predictions`).then(r => r.data),
  myPicks:     (userId: string) =>
                 api.get<Prediction[]>(`/players/${userId}/picks`).then(r => r.data),
  savePick:    (matchId: string, userId: string, home: number, away: number) =>
                 api.put<Prediction>(`/predictions/${matchId}`, { userId, homeScore: home, awayScore: away }).then(r => r.data),
  matchPicks:  (matchId: string) =>
                 api.get<MatchPicksResponse>(`/matches/${matchId}/predictions`).then(r => r.data),
  leaderboard: () => api.get<LeaderboardEntry[]>('/leaderboard').then(r => r.data),
  playerStats: (userId: string) =>
                 api.get<LeaderboardEntry>(`/leaderboard/${userId}`).then(r => r.data),
  players:     () => api.get<Player[]>('/players').then(r => r.data),
};

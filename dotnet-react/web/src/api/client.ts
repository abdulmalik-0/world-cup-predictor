import axios from 'axios';

/**
 * API client for the EnterGame .NET backend.
 *
 * Base URL points to the local .NET API in dev. For prod, set
 *   VITE_API_BASE=https://api.entergame-worldcup.com
 * in the env file.
 */
export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE ?? 'http://localhost:5080/api',
  withCredentials: false,
});

// Attach the JWT (if any) on every call.
api.interceptors.request.use((cfg) => {
  const token = localStorage.getItem('eg.token');
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});

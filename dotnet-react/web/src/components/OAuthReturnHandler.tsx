import { useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

/** If Supabase lands on / instead of /auth/callback, forward tokens/code there. */
export function OAuthReturnHandler() {
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    const { pathname, search, hash } = location;
    const oauthReturn =
      hash.includes('access_token') ||
      search.includes('code=') ||
      search.includes('error=');

    if (oauthReturn && pathname !== '/auth/callback') {
      navigate(`/auth/callback${search}${hash}`, { replace: true });
    }
  }, [location, navigate]);

  return null;
}

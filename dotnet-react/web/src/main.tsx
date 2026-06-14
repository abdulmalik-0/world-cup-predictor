import { StrictMode, Suspense, lazy, useEffect } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Route, Routes, Navigate } from 'react-router-dom'
import './index.css'
import { applyDir, useLang } from './i18n'
import { useAuth } from './hooks/useAuth'
import { useProfile } from './hooks/useProfile'
import { Navbar } from './components/Navbar'
import { OAuthReturnHandler } from './components/OAuthReturnHandler'
import { MorphingHero } from './components/MorphingHero'
import { WeAre26Background } from './components/WeAre26Background'
import { Toaster } from './lib/toast'

// Pages are code-split: each route's JS is fetched on demand instead of shipping
// in one big initial chunk — faster first paint/interactivity on mobile.
const Dashboard = lazy(() => import('./pages/Dashboard').then((m) => ({ default: m.Dashboard })))
const Leaderboard = lazy(() => import('./pages/Leaderboard').then((m) => ({ default: m.Leaderboard })))
const MyStats = lazy(() => import('./pages/MyStats').then((m) => ({ default: m.MyStats })))
const PastMatches = lazy(() => import('./pages/PastMatches').then((m) => ({ default: m.PastMatches })))
const Login = lazy(() => import('./pages/Login').then((m) => ({ default: m.Login })))
const AuthCallback = lazy(() => import('./pages/AuthCallback').then((m) => ({ default: m.AuthCallback })))
const ProfileSetup = lazy(() => import('./pages/ProfileSetup').then((m) => ({ default: m.ProfileSetup })))

// Set the lang attribute (dir stays LTR) before first paint.
applyDir()

// Always (re)load at the very TOP of the page. Disable the browser's scroll
// memory so a refresh never restores a scrolled-down position (which would
// jump past the white hero / the morph). Runs before first paint.
if ('scrollRestoration' in history) {
  history.scrollRestoration = 'manual'
}
window.scrollTo(0, 0)

const qc = new QueryClient({
  defaultOptions: { queries: { refetchOnWindowFocus: false } },
})

function App() {
  // Subscribe at the root: when the language flips, the whole tree re-renders
  // in place (no reload / remount), so every t() picks up the new strings live.
  useLang()
  const { session, user, loading: authLoading } = useAuth()
  const { needsSetup, loading: profileLoading, refresh: refreshProfile } = useProfile(user?.id)

  const booting = authLoading || (!!session && profileLoading)

  // Force the top on first mount (belt-and-suspenders with scrollRestoration).
  useEffect(() => {
    window.scrollTo(0, 0)
  }, [])

  return (
    <BrowserRouter>
      <OAuthReturnHandler />
      {/* Fixed branded background behind everything. */}
      <WeAre26Background />
      <Toaster />

      {booting ? (
        <div className="min-h-[100svh]" />
      ) : (
        <>
          {session && !needsSetup && (
            <>
              <Navbar />
              <MorphingHero />
            </>
          )}
          <Suspense fallback={<div className="min-h-[100svh]" />}>
            <Routes>
              <Route path="/auth/callback" element={<AuthCallback />} />

              {!session ? (
                <>
                  <Route path="/login" element={<Login />} />
                  <Route path="*" element={<Navigate to="/login" replace />} />
                </>
              ) : needsSetup ? (
                <Route path="*" element={<ProfileSetup onDone={refreshProfile} />} />
              ) : (
                <>
                  <Route path="/login" element={<Navigate to="/dashboard" replace />} />
                  <Route path="/dashboard" element={<Dashboard />} />
                  <Route path="/past" element={<PastMatches />} />
                  <Route path="/leaderboard" element={<Leaderboard />} />
                  <Route path="/stats" element={<MyStats />} />
                  <Route path="*" element={<Navigate to="/dashboard" replace />} />
                </>
              )}
            </Routes>
          </Suspense>
        </>
      )}
    </BrowserRouter>
  )
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={qc}>
      <App />
    </QueryClientProvider>
  </StrictMode>,
)

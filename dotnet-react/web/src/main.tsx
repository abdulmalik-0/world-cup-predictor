import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Route, Routes, Navigate } from 'react-router-dom'
import './index.css'
import { applyDir, useLang } from './i18n'
import { Navbar } from './components/Navbar'
import { MorphingHero } from './components/MorphingHero'
import { WeAre26Background } from './components/WeAre26Background'
import { Dashboard } from './pages/Dashboard'
import { Leaderboard } from './pages/Leaderboard'
import { MyStats } from './pages/MyStats'
import { PastMatches } from './pages/PastMatches'
import { Toaster } from './lib/toast'

// Set the lang attribute (dir stays LTR) before first paint.
applyDir()

const qc = new QueryClient({
  defaultOptions: { queries: { refetchOnWindowFocus: false } },
})

function App() {
  // Subscribe at the root: when the language flips, the whole tree re-renders
  // in place (no reload / remount), so every t() picks up the new strings live.
  useLang()
  return (
    <BrowserRouter>
      {/* Fixed branded background behind everything. */}
      <WeAre26Background />
      <Navbar />
      <MorphingHero />
      <Toaster />
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/past" element={<PastMatches />} />
        <Route path="/leaderboard" element={<Leaderboard />} />
        <Route path="/stats" element={<MyStats />} />
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
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

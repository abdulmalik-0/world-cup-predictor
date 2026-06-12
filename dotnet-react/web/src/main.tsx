import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Route, Routes, Navigate } from 'react-router-dom'
import './index.css'
import { applyDir } from './i18n'
import { Navbar } from './components/Navbar'
import { MorphingHero } from './components/MorphingHero'
import { WeAre26Background } from './components/WeAre26Background'
import { Dashboard } from './pages/Dashboard'
import { Leaderboard } from './pages/Leaderboard'
import { MyStats } from './pages/MyStats'

// Apply text direction (rtl for Arabic) before first paint.
applyDir()

const qc = new QueryClient({
  defaultOptions: { queries: { refetchOnWindowFocus: false } },
})

function App() {
  return (
    <BrowserRouter>
      {/* Fixed branded background behind everything. */}
      <WeAre26Background />
      <Navbar />
      <MorphingHero />
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
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

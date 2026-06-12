import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Route, Routes, Navigate } from 'react-router-dom'
import './index.css'
import { Navbar } from './components/Navbar'
import { MorphingHero } from './components/MorphingHero'
import { WeAre26Background } from './components/WeAre26Background'
import { Dashboard } from './pages/Dashboard'

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
        <Route path="/leaderboard" element={<Placeholder name="Leaderboard" />} />
        <Route path="/stats" element={<Placeholder name="My Stats" />} />
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

function Placeholder({ name }: { name: string }) {
  return (
    <div className="pt-[120px] text-center text-2xl font-bold">{name} — coming soon</div>
  )
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={qc}>
      <App />
    </QueryClientProvider>
  </StrictMode>,
)

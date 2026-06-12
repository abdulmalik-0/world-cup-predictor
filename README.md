# EnterGame · World Cup Arena 🏆

A World Cup **2026** prediction game for company employees. Players predict
match scores, earn points, and climb a live leaderboard — wrapped in the
official FIFA WC26 “NY/NJ” look (the masked **26** hero, glass cards, FIFA‑style
countdowns).

The repository contains two implementations of the same product:

| Folder | Stack | Status |
| --- | --- | --- |
| `dotnet-react/` | **ASP.NET Core API + React (Vite + TS)** | ✅ active |
| `lib/` , `web/` | Flutter Web (original) | maintained reference |

> This README focuses on the **.NET + React** edition under `dotnet-react/`.

---

## ✨ Features

- **Predictions** — pick a score for every match; locks **1 hour** before kickoff.
- **Scoring** — exact score = **3 pts**, correct winner/draw = **1 pt**, wrong = 0.
  **Saudi Arabia matches = double points.**
- **Live leaderboard** + per‑player **Statistics** (view anyone’s stats).
- **Past Matches** — final results and **everyone’s votes** (revealed only after
  voting closes, so nobody can copy).
- **Live results** synced from the free **ESPN** API (no key needed).
- **Auth** — Supabase email/password **and Google sign‑in**; predictions are
  written under **Row‑Level Security**, so you can only ever save your own.
- **Bilingual** Arabic / English with an instant, no‑reload language switch.
  Layout stays LTR and team names stay English in both languages.
- **Signature UI** — the “26 NEW YORK NEW JERSEY” video clip masked into the
  lockup, morphing from a full‑screen hero into the navbar on scroll; tuned for
  mobile performance (heavy animations/blur disabled on small screens).

---

## 🧱 Architecture

```
React (Vite + TS + Tailwind + Framer Motion)
  ├─ Auth + prediction writes ─────────────►  Supabase (Auth + Postgres RLS)
  └─ Matches / leaderboard / votes ────────►  ASP.NET Core API (EF Core)
                                                    └─►  Supabase Postgres
ESPN public API ──►  background worker / edge function  ──►  matches table
```

- **API** (`dotnet-react/api`) — ASP.NET Core minimal APIs, EF Core over the
  Supabase Postgres (session pooler), and a background worker that pulls scores
  from ESPN every 10 minutes.
- **Web** (`dotnet-react/web`) — React 19 + Vite, Tailwind, Framer Motion,
  TanStack Query, React Router, Supabase JS.
- **Database** — Supabase Postgres with RLS; predictions / leaderboard / profile
  schema lives in `supabase/migrations`.

---

## 🚀 Getting started

### Prerequisites
- .NET SDK **10**
- Node **20+**
- A Supabase project (URL + anon key; the API also needs the Postgres
  connection string)

### 1) Configure secrets (all git‑ignored)

`dotnet-react/web/.env`
```
VITE_API_BASE=http://localhost:5080/api
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon-key>
```

`dotnet-react/api/appsettings.Development.json`
```json
{
  "ConnectionStrings": {
    "Postgres": "Host=aws-1-<region>.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.<project-ref>;Password=<db-password>;SslMode=Require;Trust Server Certificate=true"
  },
  "Jwt": { "Key": "<random-secret>" }
}
```
> Use the **session pooler** (port `5432`), not the transaction pooler.

### 2) Run everything

```bash
./start-all.sh
#  API → http://localhost:5080  (Swagger at /swagger)
#  Web → http://localhost:5173
```

Or individually:
```bash
cd dotnet-react/api && dotnet run
cd dotnet-react/web && npm install && npm run dev
```

---

## ⚙️ Setup notes

- **Google sign‑in** — enable the Google provider in *Supabase → Auth →
  Providers*, add a Google Cloud OAuth client whose redirect URI is
  `https://<project-ref>.supabase.co/auth/v1/callback`, and add your app URLs
  under *Auth → URL Configuration*.
- **ESPN auto‑sync** — deploy the edge function and schedule it:
  ```bash
  supabase functions deploy sync-results-espn
  # then run supabase/migrations/012_espn_sync_cron.sql (pg_cron, every 10 min)
  ```
- **Schema** — apply `supabase/migrations/*.sql` (matches, predictions,
  leaderboard view, RLS, prediction‑window trigger, Saudi double points).

---

## 📁 Layout

```
dotnet-react/
├── api/                 ASP.NET Core API (EF Core + ESPN worker)
│   ├── Domain/  Data/  Services/  Program.cs
└── web/                 React app
    └── src/
        ├── pages/       Login · Dashboard · Leaderboard · MyStats · PastMatches
        ├── components/  MatchCard · MorphingHero · WcMask · modals …
        ├── lib/         supabase · theme · teams · time · toast
        └── i18n/        en / ar strings + reactive store
supabase/                migrations + edge functions (ESPN sync)
lib/ , web/              original Flutter Web app
```

---

## 🎯 Scoring

| Outcome | Points |
| --- | --- |
| Exact score | **3** |
| Correct winner / draw | **1** |
| Wrong | 0 |
| 🔥 Saudi Arabia match | **doubled** |

Points are computed automatically when ESPN marks a match finished.

---

## 🔐 Security

- No secrets are committed — `.env`, `appsettings.Development.json`, and
  `CREDENTIALS.md` are git‑ignored.
- Prediction writes go through Supabase **RLS** (`auth.uid() = user_id`).
- Others’ picks are hidden until the voting window closes.

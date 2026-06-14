# Malaz World Cup Arena — .NET + React Edition

Same idea as the Flutter root project, rebuilt with a more flexible stack
so the design surface is easier to iterate on.

```
dotnet-react/
├── api/   # ASP.NET Core 8 Web API + Supabase (Postgres) + ESPN sync
└── web/   # React + Vite + TypeScript + Tailwind + Framer Motion
```

## Why this split
- **API (.NET)** owns the domain logic: predictions, scoring, ESPN sync.
- **Web (React)** is a pure UI layer — every animation, hero effect, navbar
  morph etc. lives here, so design iterations don't touch backend code.
- Both talk to the SAME Supabase Postgres the Flutter version uses, so the
  user accounts and 104 World Cup 2026 matches you already loaded carry over.

## Local dev
```
cd dotnet-react/api && dotnet run
cd dotnet-react/web && npm install && npm run dev
```

## Architecture
- API: ASP.NET Minimal APIs, EF Core for Postgres (Supabase), JWT auth.
- Web: Vite + React 18 + TS, Tailwind for styling, Framer Motion for the
  hero morph, react-router for routing, TanStack Query for data.

## Google sign-in

The login page includes **Continue with Google**. One-time setup:

### 1. Google Cloud Console

1. Open [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
2. Create an **OAuth 2.0 Client ID** (type: **Web application**).
3. **Authorized JavaScript origins** — add every URL where the app runs:
   - `http://localhost:5173` (local dev)
   - `https://malaz.altamimi.tech` (production)
4. **Authorized redirect URIs** — add Supabase callback only:
   - `https://pwojrsmbgdtzmoqzwusy.supabase.co/auth/v1/callback`
5. Copy the **Client ID** and **Client secret**.

### 2. Supabase Dashboard

1. **Authentication → Providers → Google** → Enable.
2. Paste Client ID and Client secret.
3. **Authentication → URL Configuration**:
   - **Site URL:** `https://malaz.altamimi.tech`
   - **Redirect URLs:**
     - `http://localhost:5173/auth/callback`
     - `https://malaz.altamimi.tech/auth/callback`
4. (Optional) Run migration `supabase/migrations/013_google_oauth_profile.sql` in SQL Editor so Google names/avatars populate profiles.

### 3. Production `.env`

In `dotnet-react/web/.env` before building for production:

```
VITE_SITE_URL=https://malaz.altamimi.tech
```

Then rebuild and redeploy the web app.

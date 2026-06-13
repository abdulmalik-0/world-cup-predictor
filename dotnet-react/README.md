# EnterGame World Cup Arena — .NET + React Edition

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

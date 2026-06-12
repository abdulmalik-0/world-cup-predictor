#!/usr/bin/env bash
# Start both the .NET API and the React dev server in parallel.
# Press Ctrl+C once to stop both.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

if ! command -v dotnet >/dev/null 2>&1; then
  for d in /usr/local/share/dotnet /opt/homebrew/opt/dotnet/libexec; do
    [ -x "$d/dotnet" ] && export PATH="$PATH:$d" && break
  done
fi

if ! command -v dotnet >/dev/null 2>&1; then
  echo "❌ .NET SDK not on PATH. Install with: brew install --cask dotnet-sdk"
  exit 1
fi

# Make sure no stale processes are holding the ports.
lsof -ti tcp:5080 2>/dev/null | xargs kill -9 2>/dev/null || true
lsof -ti tcp:5173 2>/dev/null | xargs kill -9 2>/dev/null || true

cleanup() { kill 0 2>/dev/null || true; }
trap cleanup EXIT INT TERM

# Force the Development environment so appsettings.Development.json
# (with the Postgres connection string + JWT key) is loaded.
export ASPNETCORE_ENVIRONMENT=Development
export ASPNETCORE_URLS="http://localhost:5080"

echo "▶ Starting .NET API on http://localhost:5080 …"
(cd "$ROOT/dotnet-react/api" && dotnet run) &
API_PID=$!

echo "▶ Starting React dev server on http://localhost:5173 …"
(cd "$ROOT/dotnet-react/web" && npm run dev -- --port 5173 --strictPort) &
WEB_PID=$!

echo
echo "🌐 API:  http://localhost:5080  (Swagger at /swagger)"
echo "🎨 Web:  http://localhost:5173"
echo "Press Ctrl+C to stop both."
wait

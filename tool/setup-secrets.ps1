# Sync secrets.local.json -> env.json, web/.env, api/appsettings.Development.json, .env.docker
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\tool\setup-secrets.ps1
#   powershell -ExecutionPolicy Bypass -File .\tool\setup-secrets.ps1 -PostgresConnection "Host=...;Password=...;..."

param(
    [string]$PostgresConnection = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

$secretsPath = Join-Path $Root "secrets.local.json"
if (-not (Test-Path $secretsPath)) {
    Write-Host "secrets.local.json missing." -ForegroundColor Red
    exit 1
}

$secrets = Get-Content $secretsPath -Raw | ConvertFrom-Json

if ($PostgresConnection) {
    $secrets.POSTGRES_CONNECTION = $PostgresConnection
    $secrets | ConvertTo-Json | Set-Content $secretsPath -Encoding UTF8
}

# --- Flutter / shared ---
@{
    SUPABASE_URL = $secrets.SUPABASE_URL
    SUPABASE_ANON_KEY = $secrets.SUPABASE_ANON_KEY
} | ConvertTo-Json | Set-Content (Join-Path $Root "env.json") -Encoding UTF8

# --- React web ---
$webEnv = @"
VITE_API_BASE=http://localhost:5080/api
VITE_SUPABASE_URL=$($secrets.SUPABASE_URL)
VITE_SUPABASE_ANON_KEY=$($secrets.SUPABASE_ANON_KEY)
"@
$webEnv | Set-Content (Join-Path $Root "dotnet-react/web/.env") -Encoding UTF8 -NoNewline
Add-Content (Join-Path $Root "dotnet-react/web/.env") ""

# --- Docker (Flutter legacy) ---
$dockerEnv = @"
SUPABASE_URL=$($secrets.SUPABASE_URL)
SUPABASE_ANON_KEY=$($secrets.SUPABASE_ANON_KEY)
"@
$dockerEnv | Set-Content (Join-Path $Root ".env.docker") -Encoding UTF8

# --- .NET API ---
if ($secrets.POSTGRES_CONNECTION) {
    $apiSettings = @{
        ConnectionStrings = @{ Postgres = $secrets.POSTGRES_CONNECTION }
        Jwt = @{ Key = $secrets.JWT_KEY }
    }
    $apiSettings | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $Root "dotnet-react/api/appsettings.Development.json") -Encoding UTF8
    Write-Host "OK: dotnet-react/api/appsettings.Development.json" -ForegroundColor Green
} else {
    Write-Host "SKIP: POSTGRES_CONNECTION empty - API config not written yet." -ForegroundColor Yellow
}

Write-Host "OK: env.json" -ForegroundColor Green
Write-Host "OK: dotnet-react/web/.env" -ForegroundColor Green
Write-Host "OK: .env.docker" -ForegroundColor Green

if (-not $secrets.POSTGRES_CONNECTION) {
    Write-Host ""
    Write-Host "Need one value from Supabase (see steps in chat):" -ForegroundColor Yellow
    Write-Host "  POSTGRES_CONNECTION = Session pooler connection string" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Then run:" -ForegroundColor Cyan
    Write-Host '  powershell -ExecutionPolicy Bypass -File .\tool\setup-secrets.ps1 -PostgresConnection "Host=...;Port=5432;..."' -ForegroundColor White
}

# Push football-data.org secrets to Supabase (WC only).
# Reads supabase/.env — if Supabase CLI is missing, prints Dashboard steps.

param(
    [switch]$Manual
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$EnvFile = Join-Path $Root "supabase\.env"
$ProjectRef = "pwojrsmbgdtzmoqzwusy"

function Resolve-SupabaseCli {
    $cmd = Get-Command supabase -ErrorAction SilentlyContinue
    if ($cmd) { return @{ Exe = $cmd.Source; Args = @() } }

    $npx = Get-Command npx -ErrorAction SilentlyContinue
    if ($npx) { return @{ Exe = $npx.Source; Args = @("supabase") } }

    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if ($npm) { return @{ Exe = $npm.Source; Args = @("exec", "--", "supabase") } }

    return $null
}

function Show-ManualSteps {
    param(
        [string]$Key,
        [string]$Comp,
        [string]$Season
    )

    $dash = "https://supabase.com/dashboard/project/$ProjectRef/settings/functions"
    Write-Host ""
    Write-Host "Supabase CLI not installed. Set secrets in the Dashboard:" -ForegroundColor Yellow
    Write-Host "  $dash" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Add these Edge Function secrets:" -ForegroundColor White
    Write-Host "  FOOTBALL_API_KEY          = $Key"
    Write-Host "  FOOTBALL_COMPETITION_CODE = $Comp"
    Write-Host "  FOOTBALL_SEASON           = $Season"
    Write-Host ""
    Write-Host "Then deploy the function from Dashboard -> Edge Functions -> sync-results"
    Write-Host "(paste code from supabase/functions/sync-results/index.ts)"
    Write-Host ""
    Write-Host "Optional - install CLI for next time:" -ForegroundColor DarkGray
    Write-Host "  scoop bucket add supabase https://github.com/supabase/scoop-bucket.git"
    Write-Host "  scoop install supabase"
    Write-Host "  # or: npm install -g supabase"
    Write-Host ""
}

if (-not (Test-Path $EnvFile)) {
    Write-Host "Missing $EnvFile - copy from supabase\.env.example" -ForegroundColor Red
    exit 1
}

$vars = @{}
Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -notmatch '=') { return }
    $k, $v = $_ -split '=', 2
    $vars[$k.Trim()] = $v.Trim()
}

$key = $vars['FOOTBALL_API_KEY']
if (-not $key) {
    Write-Host "FOOTBALL_API_KEY not set in supabase\.env" -ForegroundColor Red
    exit 1
}

$comp = $vars['FOOTBALL_COMPETITION_CODE']
if (-not $comp) { $comp = 'WC' }
$season = $vars['FOOTBALL_SEASON']
if (-not $season) { $season = '2026' }

if ($Manual) {
    Show-ManualSteps -Key $key -Comp $comp -Season $season
    exit 0
}

$cli = Resolve-SupabaseCli
if (-not $cli) {
    Show-ManualSteps -Key $key -Comp $comp -Season $season
    exit 0
}

Write-Host "Setting Supabase secrets (competition=$comp season=$season)..." -ForegroundColor Cyan
$setArgs = @($cli.Args) + @(
    "secrets", "set",
    "FOOTBALL_API_KEY=$key",
    "FOOTBALL_COMPETITION_CODE=$comp",
    "FOOTBALL_SEASON=$season"
)
& $cli.Exe @setArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Deploy sync function:" -ForegroundColor Green
$deployArgs = @($cli.Args) + @("functions", "deploy", "sync-results")
Write-Host "  $($cli.Exe) $($deployArgs -join ' ')"

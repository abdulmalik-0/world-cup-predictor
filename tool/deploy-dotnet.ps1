# Deploy Malaz .NET + React to the server (port 8086).
# Only stops/replaces worldcup_predictor_* containers - does NOT touch entergame, rased, etc.
# Usage: powershell -ExecutionPolicy Bypass -File .\tool\deploy-dotnet.ps1
#        powershell -ExecutionPolicy Bypass -File .\tool\deploy-dotnet.ps1 -Server root@projects

param(
    [string]$Server = "root@192.168.100.100",
    [string]$RemotePath = "/root/projects/worldcup_predictor",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

# .NET / Node are often installed but missing from PATH in a fresh PowerShell session.
$env:Path = "C:\Program Files\dotnet;C:\Program Files\nodejs;$env:Path"

function Invoke-Checked {
    param([string]$Label, [scriptblock]$Block)
    Write-Host "==> $Label" -ForegroundColor Cyan
    & $Block
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed (exit $LASTEXITCODE)"
    }
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host ".NET SDK not found. Install .NET 10 SDK first." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js/npm not found. Install Node.js 20+ first." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "env.json")) {
    Write-Host "env.json missing - copy from env.example.json first." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "dotnet-react/api/appsettings.Development.json")) {
    Write-Host "dotnet-react/api/appsettings.Development.json missing." -ForegroundColor Red
    Write-Host "Copy appsettings.Development.json.example and set Postgres password." -ForegroundColor Yellow
    exit 1
}

$envJson = Get-Content "env.json" -Raw | ConvertFrom-Json
$supabaseUrl = $envJson.SUPABASE_URL
$supabaseKey = $envJson.SUPABASE_ANON_KEY

if (-not $SkipBuild) {
    Invoke-Checked "npm install (web)" { npm install --prefix dotnet-react/web }
    Invoke-Checked "Build React (prod)" {
        $env:VITE_API_BASE = "/api"
        $env:VITE_SUPABASE_URL = $supabaseUrl
        $env:VITE_SUPABASE_ANON_KEY = $supabaseKey
        npm run build --prefix dotnet-react/web
    }
    Invoke-Checked "Publish .NET API" {
        dotnet publish dotnet-react/api/EnterGame.Api.csproj -c Release -o build/dotnet-api
    }
} else {
    Write-Host "==> Skipping build ..." -ForegroundColor Yellow
}

if (-not (Test-Path "dotnet-react/web/dist/index.html")) {
    Write-Host "dotnet-react/web/dist missing - run without -SkipBuild first." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "build/dotnet-api/EnterGame.Api.dll")) {
    Write-Host "build/dotnet-api missing - run without -SkipBuild first." -ForegroundColor Red
    exit 1
}

Invoke-Checked "Prepare remote folder" {
    ssh $Server "mkdir -p ${RemotePath}/api ${RemotePath}/site"
}
Invoke-Checked "Upload nginx config" {
    scp tool/nginx-dotnet.conf "${Server}:${RemotePath}/nginx-dotnet.conf"
}
Invoke-Checked "Upload API" {
    scp -r build/dotnet-api/. "${Server}:${RemotePath}/api/"
}
Invoke-Checked "Upload web dist" {
    scp -r dotnet-react/web/dist/. "${Server}:${RemotePath}/site/"
}

$apiSettings = Get-Content "dotnet-react/api/appsettings.Development.json" -Raw | ConvertFrom-Json
$pgConn = $apiSettings.ConnectionStrings.Postgres
$jwtKey = $apiSettings.Jwt.Key
$pgConnEsc = $pgConn -replace "'", "'\''"

$finalizeCmd = @(
    'set -e'
    'echo "--- stopping ONLY worldcup_predictor containers ---"'
    'docker rm -f worldcup_predictor_app worldcup_predictor_api 2>/dev/null || true'
    "chmod -R a+rX ${RemotePath}/site ${RemotePath}/api"
    'docker network create worldcup_net 2>/dev/null || true'
    "docker run -d --name worldcup_predictor_api --restart always --network worldcup_net -p 5080:5080 -e ASPNETCORE_URLS=http://0.0.0.0:5080 -e ASPNETCORE_ENVIRONMENT=Production -e POSTGRES_CONNECTION='$pgConnEsc' -e JWT_KEY='$jwtKey' -v ${RemotePath}/api:/app -w /app mcr.microsoft.com/dotnet/aspnet:10.0 dotnet EnterGame.Api.dll"
    "docker run -d --name worldcup_predictor_app --restart always --network worldcup_net -p 8086:80 -v ${RemotePath}/site:/usr/share/nginx/html:ro -v ${RemotePath}/nginx-dotnet.conf:/etc/nginx/conf.d/default.conf:ro nginx:alpine"
    'echo "--- worldcup containers ---"'
    'docker ps --filter name=worldcup_predictor'
    "test -f ${RemotePath}/site/index.html"
    'echo "--- entergame still running ---"'
    'docker ps --filter name=entergame'
) -join '; '

Write-Host "==> Finalize on server ..." -ForegroundColor Cyan
Invoke-Checked "Finalize deploy" { ssh $Server $finalizeCmd }

Write-Host ""
Write-Host "Done: http://192.168.100.100:8086" -ForegroundColor Green
Write-Host "Hard refresh: Ctrl+Shift+R" -ForegroundColor Yellow

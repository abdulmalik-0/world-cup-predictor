# Local dev: .NET API + React (Windows version of start-all.sh)
# Usage: powershell -ExecutionPolicy Bypass -File .\tool\start-all.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

# .NET is often installed but missing from PATH in a fresh PowerShell session.
$dotnetDir = "C:\Program Files\dotnet"
if (Test-Path "$dotnetDir\dotnet.exe") {
    $env:Path = "$dotnetDir;$env:Path"
}

$nodeDir = "C:\Program Files\nodejs"
if (Test-Path "$nodeDir\npm.cmd") {
    $env:Path = "$nodeDir;$env:Path"
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host ".NET SDK not found. Install .NET 10 SDK first." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "dotnet-react/web/.env")) {
    Write-Host "Missing dotnet-react/web/.env - copy from .env.example and set Supabase keys." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "dotnet-react/api/appsettings.Development.json")) {
    Write-Host "Missing dotnet-react/api/appsettings.Development.json" -ForegroundColor Yellow
    Write-Host "Copy from appsettings.Development.json.example and set Postgres password." -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting .NET API on http://localhost:5080 ..." -ForegroundColor Cyan
$apiCmd = "`$env:Path='C:\Program Files\dotnet;' + `$env:Path; cd '$Root\dotnet-react\api'; `$env:ASPNETCORE_ENVIRONMENT='Development'; `$env:ASPNETCORE_URLS='http://localhost:5080'; dotnet run"
Start-Process powershell -ArgumentList @("-NoExit", "-Command", $apiCmd)

Start-Sleep -Seconds 2

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js/npm not found. Install Node.js 20+ from https://nodejs.org" -ForegroundColor Red
    exit 1
}

Write-Host "Starting React on http://localhost:5173 ..." -ForegroundColor Cyan
$webCmd = "`$env:Path='C:\Program Files\nodejs;C:\Program Files\dotnet;' + `$env:Path; cd '$Root\dotnet-react\web'; if (-not (Test-Path node_modules)) { npm install }; npm run dev -- --port 5173 --strictPort"
Start-Process powershell -ArgumentList @("-NoExit", "-Command", $webCmd)

Write-Host ""
Write-Host "API:  http://localhost:5080  (Swagger: /swagger)" -ForegroundColor Green
Write-Host "Web:  http://localhost:5173" -ForegroundColor Green

# نشر على السيرفر بدون GitHub
# الاستخدام: powershell -ExecutionPolicy Bypass -File .\tool\deploy.ps1
# بناء جاهز:     powershell -ExecutionPolicy Bypass -File .\tool\deploy.ps1 -SkipBuild

param(
    [string]$Server = "root@192.168.100.100",
    [string]$RemotePath = "/root/projects/worldcup_predictor",
    [switch]$DockerOnServer,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

function Invoke-Checked {
    param([string]$Label, [scriptblock]$Block)
    Write-Host "==> $Label" -ForegroundColor Cyan
    & $Block
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed (exit $LASTEXITCODE)"
    }
}

Write-Host "==> Project: $Root" -ForegroundColor Cyan

if (-not (Test-Path "env.json")) {
    Write-Host "env.json missing - copy from env.example.json first." -ForegroundColor Red
    exit 1
}

if ($DockerOnServer) {
    Invoke-Checked "Prepare remote folder" { ssh $Server "mkdir -p $RemotePath" }
    $items = @(
        "assets", "lib", "web", "tool",
        "pubspec.yaml", "pubspec.lock",
        "Dockerfile", "docker-compose.yml",
        ".dockerignore", "analysis_options.yaml"
    )
    foreach ($item in $items) {
        if (Test-Path $item) {
            Invoke-Checked "Upload $item" { scp -r $item "${Server}:${RemotePath}/" }
        }
    }
    Write-Host ""
    Write-Host "On server:" -ForegroundColor Yellow
    Write-Host ('  cd ' + $RemotePath + '; nano .env.docker')
    Write-Host '  docker compose --env-file .env.docker up -d --build'
    exit 0
}

if (-not $SkipBuild) {
    Invoke-Checked "Flutter build" {
        flutter pub get
        flutter build web --release --dart-define-from-file=env.json
    }
} else {
    Write-Host "==> Skipping build (using existing build/web)..." -ForegroundColor Yellow
}

if (-not (Test-Path "build/web/main.dart.js")) {
    Write-Host "build/web not found - run without -SkipBuild first." -ForegroundColor Red
    exit 1
}

$localJs = (Get-Item "build/web/main.dart.js").Length
Write-Host "    Local main.dart.js size: $localJs bytes" -ForegroundColor DarkGray

$imageDir = "build/web/assets/assets/images"
if (-not (Test-Path "$imageDir/background.png")) {
    Write-Host "Images missing in build - run: flutter clean; flutter build web ..." -ForegroundColor Red
    exit 1
}
Write-Host "    Images OK: background, wc26_logo, fifa logo" -ForegroundColor DarkGray

$archive = Join-Path $Root "build/web.tgz"
if (Test-Path $archive) { Remove-Item $archive -Force }

Invoke-Checked "Pack build/web" {
    tar -czf $archive -C build/web .
}

$archiveSize = (Get-Item $archive).Length
Write-Host "    Archive size: $archiveSize bytes" -ForegroundColor DarkGray

Invoke-Checked "Prepare remote folder" {
    ssh $Server "mkdir -p ${RemotePath}"
}
Invoke-Checked "Upload nginx config" {
    scp tool/nginx-spa.conf "${Server}:${RemotePath}/nginx-spa.conf"
}
Invoke-Checked "Upload build archive" {
    scp -C $archive "${Server}:${RemotePath}/web.tgz"
}
Invoke-Checked "Extract on server" {
    ssh $Server "rm -rf ${RemotePath}/site; mkdir -p ${RemotePath}/site && tar -xzf ${RemotePath}/web.tgz -C ${RemotePath}/site && rm -f ${RemotePath}/web.tgz"
}
if (Test-Path $archive) { Remove-Item $archive -Force }

# One SSH session: permissions + verify + docker (fewer password prompts / drops)
$finalizeCmd = @(
    "set -e",
    "chmod -R a+rX ${RemotePath}/site",
    "test -f ${RemotePath}/site/index.html",
    "test -f ${RemotePath}/site/assets/assets/images/background.png",
    "cd ${RemotePath} 2>/dev/null && docker compose --env-file .env.docker down 2>/dev/null || true",
    "docker rm -f worldcup_predictor_app worldcup_predictor_api 2>/dev/null || true",
    "for port in 8086; do for id in `$(docker ps -q --filter publish=`$port); do docker rm -f `$id 2>/dev/null || true; done; done",
    "docker run -d --name worldcup_predictor_app --restart always -p 8086:80 -v ${RemotePath}/site:/usr/share/nginx/html:ro -v ${RemotePath}/nginx-spa.conf:/etc/nginx/conf.d/default.conf:ro nginx:alpine",
    "echo '--- container ---'",
    "docker ps --filter name=worldcup_predictor_app",
    "echo '--- images ---'",
    "ls -la ${RemotePath}/site/assets/assets/images/"
) -join "; "

Write-Host "==> Finalize on server (chmod + docker + verify)..." -ForegroundColor Cyan
Write-Host '    (one SSH login - run finalize on server if upload already done)' -ForegroundColor DarkGray
Invoke-Checked "Finalize deploy" { ssh $Server $finalizeCmd }

Write-Host ""
Write-Host "Done: http://192.168.100.100:8086" -ForegroundColor Green
Write-Host "Hard refresh: Ctrl+Shift+R" -ForegroundColor Yellow

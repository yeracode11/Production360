# Installs Visual C++ 2015–2022 Redistributable (x64) on cash PCs where
# Production360 shows VCRUNTIME140 / MSVCP140 / VCRUNTIME140_1 errors.
#
# Run as Administrator:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\install-vcredist-only.ps1
#
# Silent (GPO / remote):
#   powershell -ExecutionPolicy Bypass -File install-vcredist-only.ps1 -Quiet

param(
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$RedistDir = Join-Path $PSScriptRoot "redist"
$VcRedistPath = Join-Path $RedistDir "vc_redist.x64.exe"
$VcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"

if (-not (Test-Path $RedistDir)) {
    New-Item -ItemType Directory -Path $RedistDir | Out-Null
}

if (-not (Test-Path $VcRedistPath)) {
    if ($Quiet) { Write-Host "Downloading vc_redist.x64.exe ..." }
    Invoke-WebRequest -Uri $VcRedistUrl -OutFile $VcRedistPath -UseBasicParsing
}

$args = @("/install", "/quiet", "/norestart")
if (-not $Quiet) {
    Write-Host "Installing Visual C++ Redistributable (x64) ..."
}

$p = Start-Process -FilePath $VcRedistPath -ArgumentList $args -Wait -PassThru
# 0 = success, 1638 = newer already installed, 3010 = success reboot suggested
if ($p.ExitCode -notin 0, 1638, 3010) {
    throw "vc_redist setup failed with exit code $($p.ExitCode)"
}

if (-not $Quiet) {
    Write-Host "Done. Restart Production360 (reboot only if Windows asks)." -ForegroundColor Green
}

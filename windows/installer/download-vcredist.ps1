# Download Visual C++ Redistributable for the installer bundle.
# Run from windows\installer:
#   .\download-vcredist.ps1

$ErrorActionPreference = "Stop"
$RedistDir = Join-Path $PSScriptRoot "redist"
$VcRedistPath = Join-Path $RedistDir "vc_redist.x64.exe"
$VcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"

if (-not (Test-Path $RedistDir)) {
    New-Item -ItemType Directory -Path $RedistDir | Out-Null
}

Write-Host "Downloading vc_redist.x64.exe ..."
Invoke-WebRequest -Uri $VcRedistUrl -OutFile $VcRedistPath

Write-Host "Saved to: $VcRedistPath" -ForegroundColor Green

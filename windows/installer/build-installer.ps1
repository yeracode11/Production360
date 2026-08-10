# Production360 — сборка Windows installer (Inno Setup)
# Запуск из PowerShell в папке windows\installer:
#   .\build-installer.ps1
#
# Опционально указать версию (иначе читается из pubspec.yaml):
#   .\build-installer.ps1 -Version 1.0.5

param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$RedistDir = Join-Path $PSScriptRoot "redist"
$VcRedistPath = Join-Path $RedistDir "vc_redist.x64.exe"
$VcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$IssPath = Join-Path $PSScriptRoot "Production360.iss"

function Get-VersionFromPubspec {
    $pubspec = Join-Path $RootDir "pubspec.yaml"
    $line = Get-Content $pubspec | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
    if (-not $line) {
        throw "Не удалось прочитать version из pubspec.yaml"
    }
    return ($line -replace '^version:\s*', '').Split('+')[0].Trim()
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = Get-VersionFromPubspec
}

Write-Host "==> Версия: $Version"

Write-Host "==> Flutter build windows --release"
Push-Location $RootDir
try {
    flutter pub get
    flutter build windows --release --build-name=$Version
}
finally {
    Pop-Location
}

$ReleaseDir = Join-Path $RootDir "build\windows\x64\runner\Release"
if (-not (Test-Path (Join-Path $ReleaseDir "Production360.exe"))) {
    throw "Не найден Production360.exe в $ReleaseDir"
}

if (-not (Test-Path $RedistDir)) {
    New-Item -ItemType Directory -Path $RedistDir | Out-Null
}

if (-not (Test-Path $VcRedistPath)) {
    Write-Host "==> Скачивание Visual C++ Redistributable..."
    Invoke-WebRequest -Uri $VcRedistUrl -OutFile $VcRedistPath
}

$IsccCandidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
)

$Iscc = $IsccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Iscc) {
    throw @"
Inno Setup 6 не найден.
Скачайте: https://jrsoftware.org/isdl.php
После установки запустите скрипт снова.
"@
}

Write-Host "==> Компиляция installer через Inno Setup"
& $Iscc "/DMyAppVersion=$Version" $IssPath

$OutputFile = Join-Path $RootDir "build\windows\installer\Production360-Setup-$Version.exe"
Write-Host ""
Write-Host "Готово: $OutputFile" -ForegroundColor Green

# Production360 Windows installer (Inno Setup + bundled VC++ Redistributable)
#
#   cd mobile\windows\installer
#   .\build-installer.ps1
#
# Optional:
#   .\build-installer.ps1 -Version 1.0.5 -SkipFlutterBuild

param(
    [string]$Version = "",
    [switch]$SkipFlutterBuild,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$RedistDir = Join-Path $PSScriptRoot "redist"
$VcRedistPath = Join-Path $RedistDir "vc_redist.x64.exe"
$VcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$IssPath = Join-Path $PSScriptRoot "Production360.iss"
$MinVcRedistBytes = 10MB

function Get-VersionFromPubspec {
    $pubspec = Join-Path $RootDir "pubspec.yaml"
    $line = Get-Content $pubspec | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
    if (-not $line) {
        throw "Could not read version from pubspec.yaml"
    }
    return ($line -replace '^version:\s*', '').Split('+')[0].Trim()
}

function Ensure-VcRedist {
    if (-not (Test-Path $RedistDir)) {
        New-Item -ItemType Directory -Path $RedistDir | Out-Null
    }

    $needsDownload = -not (Test-Path $VcRedistPath)
    if (-not $needsDownload) {
        $size = (Get-Item $VcRedistPath).Length
        if ($size -lt $MinVcRedistBytes) {
            Write-Host "==> vc_redist.x64.exe looks incomplete ($size bytes), re-downloading..."
            $needsDownload = $true
        }
    }

    if ($needsDownload) {
        Write-Host "==> Downloading Visual C++ Redistributable (x64)..."
        Invoke-WebRequest -Uri $VcRedistUrl -OutFile $VcRedistPath -UseBasicParsing
    }

    $finalSize = (Get-Item $VcRedistPath).Length
    if ($finalSize -lt $MinVcRedistBytes) {
        throw "vc_redist.x64.exe download failed or file is too small ($finalSize bytes)."
    }
    Write-Host "==> vc_redist.x64.exe OK ($([math]::Round($finalSize / 1MB, 1)) MB)"
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = Get-VersionFromPubspec
}

Ensure-VcRedist

if (-not $SkipFlutterBuild) {
    Write-Host "==> Version: $Version"
    Push-Location $RootDir
    try {
        if ($Clean) {
            flutter clean
        }
        flutter pub get
        flutter build windows --release --build-name=$Version
    }
    finally {
        Pop-Location
    }
}

$ReleaseDir = Join-Path $RootDir "build\windows\x64\runner\Release"
$ExePath = Join-Path $ReleaseDir "Production360.exe"
if (-not (Test-Path $ExePath)) {
    throw "Production360.exe not found in $ReleaseDir. Run flutter build windows --release first."
}

$IsccCandidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
)

$Iscc = $IsccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Iscc) {
    throw @"
Inno Setup 6 not found.
Install: https://jrsoftware.org/isdl.php
Then run this script again.
"@
}

Write-Host "==> Compiling installer (Inno Setup)..."
& $Iscc "/DMyAppVersion=$Version" $IssPath
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compile failed with exit code $LASTEXITCODE"
}

$OutputFile = Join-Path $RootDir "build\windows\installer\Production360-Setup-$Version.exe"
if (-not (Test-Path $OutputFile)) {
    throw "Expected output not found: $OutputFile"
}

Write-Host ""
Write-Host "Ready for cash PCs:" -ForegroundColor Green
Write-Host "  $OutputFile"
Write-Host ""
Write-Host "Install on each PC (admin): run Setup.exe — VC++ installs automatically."

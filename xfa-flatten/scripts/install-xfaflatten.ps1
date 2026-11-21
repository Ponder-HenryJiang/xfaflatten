# install-xfaflatten.ps1 - xfaflatten CLI bootstrap for the agent skill.
# Clone-and-run edition: uses the exe bundled in ../bin first (zero network).
# If no bundled exe is present, falls back to downloading the official slim
# package from -Url, verifying SHA256, extracting, and printing the CLI path.
# Pure ASCII; PowerShell 5.1 compatible.
#
# Usage (bundled exe, no download):
#   powershell -ExecutionPolicy Bypass -File install-xfaflatten.ps1 [-InstallDir C:\xfaflatten]
# Usage (download fallback):
#   powershell -ExecutionPolicy Bypass -File install-xfaflatten.ps1 `
#     -Url <zip-url> -Sha256Url <sha256-url> [-InstallDir C:\xfaflatten]
#
# Exit codes: 0 installed, 1 download/hash/install error, 2 hash mismatch.
param(
  [string]$Url = "",
  [string]$Sha256Url = "",
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'xfaflatten')
)

$ErrorActionPreference = 'Stop'
$cli = Join-Path $InstallDir 'xfaflatten.exe'

try {
  # ---- Preferred path: exe bundled with the skill (no network needed) ----
  $bundledDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'bin'
  $bundledExe = Join-Path $bundledDir 'xfaflatten.exe'
  if (Test-Path -LiteralPath $bundledExe) {
    Write-Output ("Using bundled CLI: " + $bundledExe)
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Copy-Item -LiteralPath $bundledExe -Destination $cli -Force
    # The native dll must sit next to the exe.
    $bundledDll = Join-Path $bundledDir 'libSkiaSharp.dll'
    if (Test-Path -LiteralPath $bundledDll) {
      Copy-Item -LiteralPath $bundledDll -Destination (Join-Path $InstallDir 'libSkiaSharp.dll') -Force
    }
    if (-not (Test-Path -LiteralPath $cli)) {
      Write-Output 'INSTALL_FAILED: xfaflatten.exe not found after copy'
      exit 1
    }
    & $cli --license-info | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Output 'SMOKE_FAILED: CLI did not start cleanly'; exit 1 }
    Write-Output ("INSTALLED: " + $cli)
    exit 0
  }

  # ---- Fallback path: download the official slim package ----
  if ([string]::IsNullOrWhiteSpace($Url)) {
    Write-Output 'NO_CLI: no bundled exe in ../bin and no -Url provided'
    exit 1
  }

  $tmp = Join-Path $env:TEMP ('xfaflatten-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
  New-Item -ItemType Directory -Path $tmp -Force | Out-Null

  try {
    Write-Output ("Downloading: " + $Url)
    $zipPath = Join-Path $tmp 'xfaflatten.zip'
    # NOTE: do not use System.Net.WebClient.DownloadFile here. On Windows
    # PowerShell 5.1 it can terminate the process silently (exit code 0)
    # mid-download, for both file:// and https:// URLs. Invoke-WebRequest
    # -OutFile -UseBasicParsing is stable.
    Invoke-WebRequest -Uri $Url -OutFile $zipPath -UseBasicParsing -TimeoutSec 300
    Write-Output ("Downloaded: " + (Get-Item $zipPath).Length + " bytes")

    $expected = ''
    if ($Sha256Url -ne '') {
      $shaPath = Join-Path $tmp 'package.sha256'
      Invoke-WebRequest -Uri $Sha256Url -OutFile $shaPath -UseBasicParsing -TimeoutSec 60
      $first = (Get-Content $shaPath -TotalCount 1) -split '\s+', 2
      if ($first.Count -ge 1) { $expected = $first[0].Trim().ToLower() }
    }
    if ($expected -eq '') {
      Write-Output 'NO_SHA256_SOURCE: proceeding without checksum verification'
    } else {
      $actual = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()
      if ($actual -ne $expected) {
        Write-Output ("SHA256_MISMATCH expected=" + $expected + " actual=" + $actual)
        exit 2
      }
      Write-Output ("SHA256 OK: " + $actual)
    }

    if (Test-Path -LiteralPath $InstallDir) {
      Write-Output ("Install dir exists, upgrading in place: " + $InstallDir)
    }
    Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force

    if (-not (Test-Path -LiteralPath $cli)) {
      $nested = Get-ChildItem -LiteralPath $InstallDir -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'xfaflatten.exe') } |
        Select-Object -First 1
      if ($nested) { $cli = Join-Path $nested.FullName 'xfaflatten.exe' }
    }
    if (-not (Test-Path -LiteralPath $cli)) {
      Write-Output 'INSTALL_FAILED: xfaflatten.exe not found after extract'
      exit 1
    }

    # Do NOT redirect native stderr with 2>&1: under PS 5.1 with
    # $ErrorActionPreference='Stop', a harmless line on stderr becomes a
    # NativeCommandError and fails the smoke test. Only the exit code matters.
    $smokeOk = $false
    for ($attempt = 1; $attempt -le 5; $attempt++) {
      try {
        & $cli --license-info | Out-Null
        if ($LASTEXITCODE -eq 0) { $smokeOk = $true; break }
      } catch { }
      if ($attempt -lt 5) { Start-Sleep -Seconds 1 }
    }
    if (-not $smokeOk) { Write-Output 'SMOKE_FAILED: CLI did not start cleanly'; exit 1 }

    Write-Output ("INSTALLED: " + $cli)
    exit 0
  }
  finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
catch {
  Write-Output ("INSTALL_ERROR: " + $_.Exception.Message)
  exit 1
}

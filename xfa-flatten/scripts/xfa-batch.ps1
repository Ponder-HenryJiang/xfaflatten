# xfa-batch.ps1 - WorkBuddy skill helper for the xfaflatten CLI.
# Locates the CLI, flattens a single PDF or every PDF in a directory,
# prints per-file OK/FAIL lines and one SUMMARY JSON line.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File xfa-batch.ps1 -InputPath <file-or-dir> `
#     [-Exe <path-to-xfaflatten.exe>] [-OutputDir <dir>] [-Overwrite]
#
# Exit codes: 0 all succeeded, 1 bad input, 2 some failed, 4 CLI not found.
param(
  [Parameter(Mandatory = $true)]
  [string]$InputPath,
  [string]$Exe = "",
  [string]$OutputDir = "",
  [switch]$Overwrite
)

function Find-Cli {
  if ($Exe -ne '' -and (Test-Path -LiteralPath $Exe)) {
    return (Resolve-Path -LiteralPath $Exe).Path
  }
  $candidates = @()
  if ($env:XFAFLATTEN_EXE) { $candidates += $env:XFAFLATTEN_EXE }
  $cmd = Get-Command xfaflatten -ErrorAction SilentlyContinue
  if ($cmd) { $candidates += $cmd.Source }
  $candidates += @(
    (Join-Path (Get-Location) 'xfaflatten\xfaflatten.exe'),
    (Join-Path (Get-Location) 'xfaflatten.exe'),
    'C:\xfaflatten\xfaflatten.exe',
    (Join-Path $env:LOCALAPPDATA 'xfaflatten\xfaflatten.exe'),
    (Join-Path $env:ProgramFiles 'xfaflatten\xfaflatten.exe')
  )
  foreach ($c in $candidates) {
    if ($c -and (Test-Path -LiteralPath $c)) { return (Resolve-Path -LiteralPath $c).Path }
  }
  return $null
}

$cli = Find-Cli
if (-not $cli) {
  Write-Output 'XFAFLATTEN_NOT_FOUND'
  exit 4
}
Write-Output ("CLI: " + $cli)

# Collect input files.
$files = @()
if (Test-Path -LiteralPath $InputPath -PathType Container) {
  $files = @(Get-ChildItem -LiteralPath $InputPath -Filter *.pdf -File |
    Where-Object { $_.Name -notlike '*.flat.pdf' } |
    ForEach-Object { $_.FullName })
}
elseif (Test-Path -LiteralPath $InputPath -PathType Leaf) {
  $files = @((Resolve-Path -LiteralPath $InputPath).Path)
}
else {
  Write-Output ("INPUT_NOT_FOUND: " + $InputPath)
  exit 1
}
if ($files.Count -eq 0) {
  Write-Output 'NO_PDF_FILES'
  exit 1
}

if ($OutputDir -ne '' -and -not (Test-Path -LiteralPath $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$results = @()
$ok = 0; $fail = 0; $limited = 0
foreach ($f in $files) {
  if ($OutputDir -ne '') {
    $base = [IO.Path]::GetFileNameWithoutExtension($f)
    $out = Join-Path $OutputDir ($base + '.flat.pdf')
  }
  else {
    $out = [IO.Path]::ChangeExtension($f, '.flat.pdf')
  }

  $cliArgs = @($f, $out, '--json')
  if ($Overwrite) { $cliArgs += '--overwrite' }

  $stdout = & $cli @cliArgs 2>&1
  $code = $LASTEXITCODE
  $jsonLine = $stdout | Where-Object { "$_" -match '^\{' } | Select-Object -Last 1
  $info = $null
  if ($jsonLine) {
    try { $info = "$jsonLine" | ConvertFrom-Json } catch { $info = $null }
  }

  if ($code -eq 0 -and $info) {
    $ok++
    if ($info.limited) { $limited++ }
    $results += $info
    Write-Output ("OK  " + $f + " -> " + $out + " pages=" + $info.outputPages + "/" + $info.pages + " limited=" + $info.limited + " licensed=" + $info.licensed)
  }
  else {
    $fail++
    $msg = ""
    if ($stdout) { $msg = "$($stdout | Select-Object -Last 1)" }
    Write-Output ("FAIL(" + $code + ")  " + $f + "  " + $msg)
    $results += @{ input = $f; exit = $code; error = $msg }
  }
}

$summary = @{ cli = $cli; total = $files.Count; ok = $ok; failed = $fail; limited = $limited; results = $results }
Write-Output ("SUMMARY: " + ($summary | ConvertTo-Json -Depth 4 -Compress))
if ($fail -gt 0) { exit 2 } else { exit 0 }

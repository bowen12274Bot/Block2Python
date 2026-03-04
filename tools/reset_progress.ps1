$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$path = Join-Path $repoRoot ".block2python/progress.json"

if (Test-Path $path) {
  Remove-Item -Force $path
  Write-Host "Removed: $path"
} else {
  Write-Host "No progress file: $path"
}


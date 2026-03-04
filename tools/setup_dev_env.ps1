$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot

if (-not (Test-Path ".venv")) {
  Write-Host "Creating venv: .venv"
  py -3 -m venv .venv
}

$py = Join-Path $repoRoot ".venv\\Scripts\\python.exe"
if (-not (Test-Path $py)) {
  throw "Expected venv python not found: $py"
}

Write-Host "Upgrading pip..."
& $py -m pip install --upgrade pip

Write-Host "Installing dependencies..."
& $py -m pip install PySide6

Write-Host "Done."

Set-Location $pwdPath


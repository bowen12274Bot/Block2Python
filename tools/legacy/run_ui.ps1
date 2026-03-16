$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pwdPath = (Get-Location).Path
Set-Location $repoRoot
$env:PYTHONPATH = Join-Path $repoRoot "src"

$venvPy = Join-Path $repoRoot ".venv\\Scripts\\python.exe"
if (Test-Path $venvPy) {
  & $venvPy -c "import PySide6; print('PySide6', PySide6.__version__)" | Out-Host
  & $venvPy -m block2python.ui
} else {
  Write-Host "Missing .venv. Run: tools/setup_dev_env.ps1"
  exit 1
}

Set-Location $pwdPath

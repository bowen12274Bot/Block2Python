param(
  [switch]$RecreateVenv = $false,
  [switch]$SkipGate = $false,
  [switch]$SkipMLE = $true,
  [int]$CovFailUnder = 70,
  [switch]$RequireBlocklyVendor = $false
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot

function Get-PythonBootstrapCommand {
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @("py", "-3")
  }

  if (Get-Command python -ErrorAction SilentlyContinue) {
    return @("python")
  }

  throw "Cannot find Python launcher. Install Python 3.10+ and ensure 'py' or 'python' is in PATH."
}

function Invoke-Cmd {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [string[]]$Command
  )

  Write-Host ""
  Write-Host "=== $Name ===" -ForegroundColor Cyan
  Write-Host ("$($Command -join ' ')") -ForegroundColor DarkGray

  & $Command[0] $Command[1..($Command.Length - 1)]
  if ($LASTEXITCODE -ne 0) {
    throw "$Name failed with exit code $LASTEXITCODE"
  }
}

try {
  $pyBootstrap = Get-PythonBootstrapCommand
  $venvDir = Join-Path $repoRoot ".venv"
  $venvPy = Join-Path $repoRoot ".venv\Scripts\python.exe"

  if ($RecreateVenv -and (Test-Path $venvDir)) {
    Write-Host "Removing existing virtual environment..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $venvDir
  }

  if (-not (Test-Path $venvPy)) {
    Write-Host "Creating virtual environment at .venv..." -ForegroundColor Cyan
    & $pyBootstrap[0] $pyBootstrap[1..($pyBootstrap.Length - 1)] -m venv .venv
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to create .venv"
    }
  }

  Invoke-Cmd -Name "Upgrade pip" -Command @($venvPy, "-m", "pip", "install", "--upgrade", "pip")
  Invoke-Cmd -Name "Install requirements.txt" -Command @($venvPy, "-m", "pip", "install", "-r", "requirements.txt")
  Invoke-Cmd -Name "Install package in editable mode" -Command @($venvPy, "-m", "pip", "install", "-e", ".[dev]")

  if (-not $SkipGate) {
    $gateArgs = @(
      "-ExecutionPolicy", "Bypass",
      "-File", (Join-Path $PSScriptRoot "run_project_gate.ps1"),
      "-CovFailUnder", "$CovFailUnder"
    )

    if ($SkipMLE) {
      $gateArgs += "-SkipMLE"
    }

    if ($RequireBlocklyVendor) {
      $gateArgs += "-RequireBlocklyVendor"
    }

    $gateCommand = @("powershell") + $gateArgs
    Invoke-Cmd -Name "Run project gate" -Command $gateCommand
  } else {
    Write-Host ""
    Write-Host "Skipped project gate check (-SkipGate)." -ForegroundColor Yellow
  }

  Write-Host ""
  Write-Host "Setup completed." -ForegroundColor Green
  Write-Host "Activate venv:" -ForegroundColor Green
  Write-Host "  .\\.venv\\Scripts\\Activate.ps1" -ForegroundColor Green
}
finally {
  Set-Location $pwdPath
}

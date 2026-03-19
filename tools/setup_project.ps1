param(
  [switch]$RecreateVenv = $false,
  [int]$SkipGate = 0,
  [int]$SkipMLE = 1,
  [int]$CovFailUnder = 70,
  [switch]$RequireBlocklyVendor = $false,
  [switch]$SkipGodot = $false,
  [string]$GodotVersion = "4.6.1",
  [switch]$SkipWasmtime = $false,
  [switch]$IncludeBlockly = $false,
  [string]$BlocklyVersion = "12.4.1",
  [string]$BlocklyDistUrl = "https://github.com/RaspberryPiFoundation/blockly/releases/download/blockly-v12.4.1/blockly-12.4.1.tgz",
  [string]$BlocklyDistDir = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot

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
  $setupArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $PSScriptRoot "setup_dev_env.ps1"),
    "-GodotVersion", $GodotVersion,
    "-BlocklyVersion", $BlocklyVersion,
    "-BlocklyDistUrl", $BlocklyDistUrl
  )

  if ($RecreateVenv) {
    $setupArgs += "-RecreateVenv"
  }

  if ($SkipGodot) {
    $setupArgs += "-SkipGodot"
  }

  if ($SkipWasmtime) {
    $setupArgs += "-SkipWasmtime"
  }

  if ($IncludeBlockly) {
    $setupArgs += "-IncludeBlockly"
  }

  if ($BlocklyDistDir) {
    $setupArgs += @("-BlocklyDistDir", $BlocklyDistDir)
  }

  Invoke-Cmd -Name "Setup development environment" -Command (@("powershell") + $setupArgs)

  if (-not [bool]$SkipGate) {
    $gateArgs = @(
      "-ExecutionPolicy", "Bypass",
      "-File", (Join-Path $PSScriptRoot "run_project_gate.ps1"),
      "-CovFailUnder", "$CovFailUnder"
    )

    if ([bool]$SkipMLE) {
      $gateArgs += "-SkipMLE"
    }

    if ($RequireBlocklyVendor) {
      $gateArgs += "-RequireBlocklyVendor"
    }

    Invoke-Cmd -Name "Run project gate" -Command (@("powershell") + $gateArgs)
  } else {
    Write-Host ""
    Write-Host "Skipped project gate check (-SkipGate)." -ForegroundColor Yellow
  }

  Write-Host ""
  Write-Host "Project setup completed." -ForegroundColor Green
}
finally {
  Set-Location $pwdPath
}

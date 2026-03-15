param(
  [switch]$Console,
  [string]$GodotVersion = "4.6.1"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot

function Resolve-GodotExecutable {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [switch]$UseConsole
  )

  $exeName = if ($UseConsole) {
    "Godot_v$Version-stable_win64_console.exe"
  } else {
    "Godot_v$Version-stable_win64.exe"
  }

  $candidates = @(
    (Join-Path $repoRoot ".block2python\\godot\\$Version\\$exeName"),
    (Join-Path $repoRoot $exeName),
    (Join-Path $repoRoot "tools\\$exeName")
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  $fromPath = Get-Command $exeName -ErrorAction SilentlyContinue
  if ($fromPath) {
    return $fromPath.Source
  }

  return $null
}

try {
  $godotExe = Resolve-GodotExecutable -Version $GodotVersion -UseConsole:$Console
  if (-not $godotExe) {
    throw "Godot executable not found. Run tools/setup_dev_env.ps1 first, or place Godot in .block2python\\godot\\$GodotVersion\\"
  }

  $projectPath = Join-Path $repoRoot "godot_poc"
  $projectFile = Join-Path $projectPath "project.godot"
  if (-not (Test-Path $projectFile)) {
    throw "Godot project file not found: $projectFile"
  }

  Write-Host "Launching Godot project..."
  Write-Host "Executable: $godotExe"
  Write-Host "Project: $projectPath"

  & $godotExe --path $projectPath
}
finally {
  Set-Location $pwdPath
}

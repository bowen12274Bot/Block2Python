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

function Get-MissingImportArtifacts {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath
  )

  $artRoot = Join-Path $ProjectPath "art"
  if (-not (Test-Path $artRoot)) {
    return @()
  }

  $missing = New-Object System.Collections.Generic.List[string]
  $importFiles = Get-ChildItem -Path $artRoot -Recurse -Filter "*.import" -File -ErrorAction SilentlyContinue

  foreach ($importFile in $importFiles) {
    $remapLine = Select-String -Path $importFile.FullName -Pattern '^path="res://(.+)"$' | Select-Object -First 1
    if (-not $remapLine) {
      continue
    }

    $artifactRelativePath = $remapLine.Matches[0].Groups[1].Value -replace '/', '\\'
    $artifactAbsolutePath = Join-Path $ProjectPath $artifactRelativePath

    if (-not (Test-Path $artifactAbsolutePath)) {
      $missing.Add($artifactAbsolutePath)
    }
  }

  return $missing
}

function Ensure-GodotImports {
  param(
    [Parameter(Mandatory = $true)]
    [string]$GodotImportExecutable,
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath
  )

  $importDir = Join-Path $ProjectPath ".godot\imported"
  $needsImport = $false
  if (-not (Test-Path $importDir)) {
    $needsImport = $true
  }
  else {
    $ctexCount = @(Get-ChildItem -Path $importDir -Filter "*.ctex" -File -ErrorAction SilentlyContinue).Count
    if ($ctexCount -eq 0) {
      $needsImport = $true
    }
  }

  $missingArtifacts = Get-MissingImportArtifacts -ProjectPath $ProjectPath
  if ($missingArtifacts.Count -gt 0) {
    $needsImport = $true
  }

  if (-not $needsImport) {
    return
  }

  if ($missingArtifacts.Count -gt 0) {
    Write-Host "Import cache incomplete ($($missingArtifacts.Count) missing artifacts). Regenerating Godot imports..."
  }
  else {
    Write-Host "Import cache missing. Regenerating Godot imports..."
  }

  & $GodotImportExecutable --path $ProjectPath --headless --import

  $remainingMissingArtifacts = Get-MissingImportArtifacts -ProjectPath $ProjectPath
  if ($remainingMissingArtifacts.Count -gt 0) {
    Write-Warning "Import cache still incomplete after first pass ($($remainingMissingArtifacts.Count) missing artifacts)."
    Write-Warning "Forcing full import cache rebuild..."

    $importDir = Join-Path $ProjectPath ".godot\imported"
    if (Test-Path $importDir) {
      Remove-Item -Path $importDir -Recurse -Force
      New-Item -ItemType Directory -Path $importDir -Force | Out-Null
    }

    & $GodotImportExecutable --path $ProjectPath --headless --import
  }

  $remainingMissingArtifacts = Get-MissingImportArtifacts -ProjectPath $ProjectPath
  if ($remainingMissingArtifacts.Count -gt 0) {
    Write-Warning "Godot import cache is still incomplete after reimport ($($remainingMissingArtifacts.Count) missing artifacts)."
    Write-Warning "Example missing artifact: $($remainingMissingArtifacts[0])"
  }
}

try {
  $godotExe = Resolve-GodotExecutable -Version $GodotVersion -UseConsole:$Console
  if (-not $godotExe) {
    throw "Godot executable not found. Run tools/setup_dev_env.ps1 first, or place Godot in .block2python\\godot\\$GodotVersion\\"
  }

  $godotImportExe = Resolve-GodotExecutable -Version $GodotVersion -UseConsole:$true
  if (-not $godotImportExe) {
    $godotImportExe = $godotExe
  }

  $projectPath = Join-Path $repoRoot "godot_poc"
  $projectFile = Join-Path $projectPath "project.godot"
  if (-not (Test-Path $projectFile)) {
    throw "Godot project file not found: $projectFile"
  }

  $logDir = Join-Path $repoRoot "log"
  New-Item -ItemType Directory -Path $logDir -Force | Out-Null
  $godotLogFile = Join-Path $logDir "godot_client.log"

  Write-Host "Launching Godot project..."
  Write-Host "Executable: $godotExe"
  Write-Host "Project: $projectPath"
  Write-Host "Log file: $godotLogFile"

  Ensure-GodotImports -GodotImportExecutable $godotImportExe -ProjectPath $projectPath

  & $godotExe --path $projectPath --log-file $godotLogFile
}
finally {
  Set-Location $pwdPath
}

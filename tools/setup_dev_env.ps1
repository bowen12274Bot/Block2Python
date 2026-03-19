param(
  [switch]$SkipGodot,
  [string]$GodotVersion = "4.6.1",
  [switch]$SkipWasmtime,
  [int]$IncludeBlockly = 1,
  [string]$BlocklyVersion = "12.4.1",
  [string]$BlocklyDistUrl = "https://github.com/RaspberryPiFoundation/blockly/releases/download/blockly-v12.4.1/blockly-12.4.1.tgz",
  [string]$BlocklyDistDir = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot

function New-DirectoryIfMissing {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Install-Venv {
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
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to upgrade pip"
  }

  Write-Host "Installing requirements.txt..."
  & $py -m pip install -r requirements.txt
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to install requirements.txt"
  }

  Write-Host "Installing editable package with dev extras..."
  & $py -m pip install -e ".[dev]"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to install package in editable mode"
  }
}

function Expand-ZipToDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,
    [Parameter(Mandatory = $true)]
    [string]$DestinationDir
  )

  if (Test-Path $DestinationDir) {
    Remove-Item -Recurse -Force $DestinationDir
  }
  New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
  Expand-Archive -Path $ZipPath -DestinationPath $DestinationDir -Force
}

function Expand-PackageToDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ArchivePath,
    [Parameter(Mandatory = $true)]
    [string]$DestinationDir
  )

  if (Test-Path $DestinationDir) {
    Remove-Item -Recurse -Force $DestinationDir
  }
  New-DirectoryIfMissing -Path $DestinationDir

  $extension = [System.IO.Path]::GetExtension($ArchivePath).ToLowerInvariant()
  if ($extension -eq ".zip") {
    Expand-Archive -Path $ArchivePath -DestinationPath $DestinationDir -Force
    return
  }

  & tar -xf $ArchivePath -C $DestinationDir
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to extract archive with tar: $ArchivePath"
  }
}

function Install-Godot {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Version
  )

  $releaseTag = "$Version-stable"
  $godotRoot = Join-Path $repoRoot ".block2python\\godot\\$Version"
  $downloadRoot = Join-Path $repoRoot ".block2python\\downloads\\godot\\$Version"
  $guiExeName = "Godot_v$Version-stable_win64.exe"
  $consoleExeName = "Godot_v$Version-stable_win64_console.exe"
  $guiZipName = "$guiExeName.zip"
  $guiExePath = Join-Path $godotRoot $guiExeName
  $consoleExePath = Join-Path $godotRoot $consoleExeName

  if ((Test-Path $guiExePath) -and (Test-Path $consoleExePath)) {
    Write-Host "Godot $Version already exists at $godotRoot"
    return
  }

  New-DirectoryIfMissing -Path $godotRoot
  New-DirectoryIfMissing -Path $downloadRoot

  $guiZipPath = Join-Path $downloadRoot $guiZipName
  $extractDir = Join-Path $downloadRoot "gui"
  $guiUrl = "https://github.com/godotengine/godot-builds/releases/download/$releaseTag/$guiZipName"

  if ((-not (Test-Path $guiExePath)) -or (-not (Test-Path $consoleExePath))) {
    if (-not (Test-Path $guiZipPath)) {
      Write-Host "Downloading $guiZipName..."
      Invoke-WebRequest -Uri $guiUrl -OutFile $guiZipPath
    } else {
      Write-Host "Reusing downloaded archive: $guiZipPath"
    }

    $downloadedGuiExe = Join-Path $extractDir $guiExeName
    $downloadedConsoleExe = Join-Path $extractDir $consoleExeName
    if ((-not (Test-Path $downloadedGuiExe)) -or (-not (Test-Path $downloadedConsoleExe))) {
      Write-Host "Extracting $guiZipName..."
      Expand-ZipToDirectory -ZipPath $guiZipPath -DestinationDir $extractDir
    }
  }

  $downloadedGuiExe = Join-Path $extractDir $guiExeName
  $downloadedConsoleExe = Join-Path $extractDir $consoleExeName

  if (-not (Test-Path $downloadedGuiExe)) {
    throw "Expected Godot executable not found after extraction: $downloadedGuiExe"
  }
  if (-not (Test-Path $downloadedConsoleExe)) {
    throw "Expected Godot console executable not found after extraction: $downloadedConsoleExe"
  }

  Move-Item -Force $downloadedGuiExe $guiExePath
  Move-Item -Force $downloadedConsoleExe $consoleExePath

  Write-Host "Godot $Version installed to $godotRoot"
}

function Install-Wasmtime {
  $toolRoot = Join-Path $repoRoot ".block2python\\tools\\wasmtime"
  $downloadRoot = Join-Path $repoRoot ".block2python\\downloads\\wasmtime"
  $exePath = Join-Path $toolRoot "wasmtime.exe"

  if (Test-Path $exePath) {
    Write-Host "Wasmtime already exists at $exePath"
    return
  }

  New-DirectoryIfMissing -Path $toolRoot
  New-DirectoryIfMissing -Path $downloadRoot

  $releaseApi = "https://api.github.com/repos/bytecodealliance/wasmtime/releases/latest"
  Write-Host "Fetching latest Wasmtime release metadata..."
  $release = Invoke-RestMethod -Uri $releaseApi
  if (-not $release) {
    throw "Failed to fetch Wasmtime release metadata."
  }

  $asset = $release.assets | Where-Object { $_.name -match '^wasmtime-v.+-x86_64-windows\.zip$' } | Select-Object -First 1
  if (-not $asset) {
    throw "Could not find Wasmtime Windows x86_64 zip asset in latest release."
  }

  $archivePath = Join-Path $downloadRoot $asset.name
  $extractDir = Join-Path $downloadRoot ($asset.name -replace '\.zip$', '')

  if (-not (Test-Path $archivePath)) {
    Write-Host "Downloading $($asset.name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archivePath
  } else {
    Write-Host "Reusing downloaded archive: $archivePath"
  }

  $downloadedExe = Get-ChildItem -Path $extractDir -Recurse -Filter "wasmtime.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $downloadedExe) {
    Write-Host "Extracting $($asset.name)..."
    Expand-ZipToDirectory -ZipPath $archivePath -DestinationDir $extractDir
    $downloadedExe = Get-ChildItem -Path $extractDir -Recurse -Filter "wasmtime.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
  } else {
    Write-Host "Reusing extracted Wasmtime: $extractDir"
  }

  if (-not $downloadedExe) {
    throw "Expected wasmtime.exe not found after extraction under: $extractDir"
  }

  Copy-Item -Force -Path $downloadedExe.FullName -Destination $exePath
  Write-Host "Wasmtime installed to $exePath"
}

function Copy-BlocklyVendorFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDir
  )

  $outDir = Join-Path $repoRoot "assets\\blockly\\vendor"
  New-DirectoryIfMissing -Path $outDir
  New-DirectoryIfMissing -Path (Join-Path $outDir "msg")

  function Copy-RequiredFile {
    param(
      [Parameter(Mandatory = $true)]
      [string]$RelativePath
    )

    $sourcePath = Join-Path $SourceDir $RelativePath
    if (-not (Test-Path $sourcePath)) {
      throw "Missing Blockly dist file: $sourcePath"
    }
    $destinationPath = Join-Path $outDir $RelativePath
    $destinationParent = Split-Path -Parent $destinationPath
    New-DirectoryIfMissing -Path $destinationParent
    Copy-Item -Force -Path $sourcePath -Destination $destinationPath
  }

  Copy-RequiredFile -RelativePath "blockly_compressed.js"
  Copy-RequiredFile -RelativePath "blocks_compressed.js"
  Copy-RequiredFile -RelativePath "python_compressed.js"
  Copy-RequiredFile -RelativePath "msg\\zh-hant.js"

  Write-Host "Vendored Blockly files to: $outDir"
}

function Install-Blockly {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$DistUrl,
    [string]$DistDir
  )

  if ($DistDir) {
    if (-not (Test-Path $DistDir)) {
      throw "Blockly dist directory not found: $DistDir"
    }
    Write-Host "Using local Blockly dist directory: $DistDir"
    Copy-BlocklyVendorFiles -SourceDir $DistDir
    return
  }

  $vendorRoot = Join-Path $repoRoot ".block2python\\vendor\\blockly-$Version"
  $downloadsRoot = Join-Path $repoRoot ".block2python\\downloads\\blockly\\$Version"
  $archiveName = [System.IO.Path]::GetFileName(([System.Uri]$DistUrl).AbsolutePath)
  $archivePath = Join-Path $downloadsRoot $archiveName
  $packageDir = Join-Path $vendorRoot "package"

  New-DirectoryIfMissing -Path $vendorRoot
  New-DirectoryIfMissing -Path $downloadsRoot

  if (-not (Test-Path $archivePath)) {
    Write-Host "Downloading Blockly dist $archiveName..."
    Invoke-WebRequest -Uri $DistUrl -OutFile $archivePath
  } else {
    Write-Host "Reusing downloaded Blockly archive: $archivePath"
  }

  if (-not (Test-Path $packageDir)) {
    Write-Host "Extracting Blockly dist..."
    Expand-PackageToDirectory -ArchivePath $archivePath -DestinationDir $vendorRoot
  } else {
    Write-Host "Reusing extracted Blockly dist: $packageDir"
  }

  Copy-BlocklyVendorFiles -SourceDir $packageDir
}

try {
  Install-Venv

  if (-not $SkipGodot) {
    Install-Godot -Version $GodotVersion
  } else {
    Write-Host "Skipping Godot download."
  }

  if (-not $SkipWasmtime) {
    Install-Wasmtime
  } else {
    Write-Host "Skipping Wasmtime download."
  }

  if ([bool]$IncludeBlockly) {
    Install-Blockly -Version $BlocklyVersion -DistUrl $BlocklyDistUrl -DistDir $BlocklyDistDir
  } else {
    Write-Host "Skipping Blockly download."
  }

  Write-Host "Done."
}
finally {
  Set-Location $pwdPath
}

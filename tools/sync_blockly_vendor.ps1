$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot

function Ensure-Directory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  New-Item -ItemType Directory -Path $Path -Force | Out-Null
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
  Ensure-Directory -Path $DestinationDir

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

function Copy-BlocklyVendorFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDir
  )

  $outDir = Join-Path $repoRoot "assets\\blockly\\vendor"
  Ensure-Directory -Path $outDir
  Ensure-Directory -Path (Join-Path $outDir "msg")

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
    Ensure-Directory -Path $destinationParent
    Copy-Item -Force -Path $sourcePath -Destination $destinationPath
  }

  Copy-RequiredFile -RelativePath "blockly_compressed.js"
  Copy-RequiredFile -RelativePath "blocks_compressed.js"
  Copy-RequiredFile -RelativePath "python_compressed.js"
  Copy-RequiredFile -RelativePath "msg\\zh-hant.js"

  Write-Host "Vendored Blockly files to: $outDir"
}

if (-not $env:BLOCKLY_DIST_URL -and -not $env:BLOCKLY_DIST_ZIP -and -not $env:BLOCKLY_DIST_DIR) {
  Write-Host "Provide Blockly dist as either:" -ForegroundColor Yellow
  Write-Host "  - BLOCKLY_DIST_URL : a URL to a zip/tgz containing Blockly dist files" -ForegroundColor Yellow
  Write-Host "  - BLOCKLY_DIST_ZIP : a local archive path" -ForegroundColor Yellow
  Write-Host "  - BLOCKLY_DIST_DIR : an extracted package directory" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Example URL:" -ForegroundColor Yellow
  Write-Host "  https://github.com/RaspberryPiFoundation/blockly/releases/download/blockly-v12.4.1/blockly-12.4.1.tgz" -ForegroundColor Yellow
  Write-Host "Example DIR:" -ForegroundColor Yellow
  Write-Host "  .block2python\\vendor\\blockly-12.4.1\\package" -ForegroundColor Yellow
  Set-Location $pwdPath
  exit 1
}

$version = if ($env:BLOCKLY_VERSION) { $env:BLOCKLY_VERSION } else { "12.4.1" }
$downloadsRoot = Join-Path $repoRoot ".block2python\\downloads\\blockly\\$version"
$vendorRoot = Join-Path $repoRoot ".block2python\\vendor\\blockly-$version"
$packageDir = Join-Path $vendorRoot "package"

if ($env:BLOCKLY_DIST_DIR) {
  $sourceDir = $env:BLOCKLY_DIST_DIR
  if (-not (Test-Path $sourceDir)) {
    throw "BLOCKLY_DIST_DIR not found: $sourceDir"
  }
  Write-Host "Using extracted Blockly dist directory: $sourceDir"
  Copy-BlocklyVendorFiles -SourceDir $sourceDir
  Set-Location $pwdPath
  exit 0
}

Ensure-Directory -Path $downloadsRoot

if ($env:BLOCKLY_DIST_ZIP) {
  $archiveSource = $env:BLOCKLY_DIST_ZIP
  if (-not (Test-Path $archiveSource)) {
    throw "BLOCKLY_DIST_ZIP not found: $archiveSource"
  }
  $archiveName = Split-Path -Leaf $archiveSource
  $archivePath = Join-Path $downloadsRoot $archiveName
  if (-not (Test-Path $archivePath)) {
    Write-Host "Copying Blockly dist archive from local path..."
    Copy-Item -Force -Path $archiveSource -Destination $archivePath
  } else {
    Write-Host "Reusing copied Blockly archive: $archivePath"
  }
} else {
  $archiveName = [System.IO.Path]::GetFileName(([System.Uri]$env:BLOCKLY_DIST_URL).AbsolutePath)
  $archivePath = Join-Path $downloadsRoot $archiveName
  if (-not (Test-Path $archivePath)) {
    Write-Host "Downloading Blockly dist archive..."
    Invoke-WebRequest -Uri $env:BLOCKLY_DIST_URL -OutFile $archivePath
  } else {
    Write-Host "Reusing downloaded Blockly archive: $archivePath"
  }
}

if (-not (Test-Path $packageDir)) {
  Write-Host "Extracting Blockly dist..."
  Expand-PackageToDirectory -ArchivePath $archivePath -DestinationDir $vendorRoot
} else {
  Write-Host "Reusing extracted Blockly dist: $packageDir"
}

Copy-BlocklyVendorFiles -SourceDir $packageDir

Set-Location $pwdPath

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot

$outDir = Join-Path $repoRoot "assets\\blockly\\vendor"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $outDir "msg") | Out-Null

if (-not $env:BLOCKLY_DIST_URL) {
  if (-not $env:BLOCKLY_DIST_ZIP) {
    Write-Host "Provide Blockly dist as either:" -ForegroundColor Yellow
    Write-Host "  - BLOCKLY_DIST_URL : a URL to a zip containing Blockly dist files" -ForegroundColor Yellow
    Write-Host "  - BLOCKLY_DIST_ZIP : a local zip path (recommended if you downloaded manually)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This script intentionally avoids hard-coding a version/URL." -ForegroundColor Yellow
    Set-Location $pwdPath
    exit 1
  }
}

$zipPath = Join-Path $repoRoot ".block2python\\blockly_dist.zip"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $zipPath) | Out-Null

if ($env:BLOCKLY_DIST_ZIP) {
  $srcZip = $env:BLOCKLY_DIST_ZIP
  if (-not (Test-Path $srcZip)) {
    throw "BLOCKLY_DIST_ZIP not found: $srcZip"
  }
  Write-Host "Copying Blockly dist zip from local path..."
  Copy-Item -Force -Path $srcZip -Destination $zipPath
} else {
  Write-Host "Downloading Blockly dist zip..."
  Invoke-WebRequest -Uri $env:BLOCKLY_DIST_URL -OutFile $zipPath
}

$tmpDir = Join-Path $repoRoot ".block2python\\blockly_dist_tmp"
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

Write-Host "Extracting..."
Expand-Archive -Force -Path $zipPath -DestinationPath $tmpDir

function Copy-One($relativeName) {
  $src = Get-ChildItem -Recurse -File -Path $tmpDir | Where-Object { $_.Name -eq $relativeName } | Select-Object -First 1
  if (-not $src) { throw "Missing file in zip: $relativeName" }
  Copy-Item -Force -Path $src.FullName -Destination (Join-Path $outDir $relativeName)
}

Copy-One "blockly_compressed.js"
Copy-One "blocks_compressed.js"
Copy-One "python_compressed.js"

$msgFile = Get-ChildItem -Recurse -File -Path $tmpDir | Where-Object { $_.Name -eq "zh-hant.js" } | Select-Object -First 1
if (-not $msgFile) {
  Write-Host "Warning: msg/zh-hant.js not found in zip. You'll need to add a language file manually." -ForegroundColor Yellow
} else {
  Copy-Item -Force -Path $msgFile.FullName -Destination (Join-Path $outDir "msg\\zh-hant.js")
}

Write-Host "Vendored files to: $outDir"

Set-Location $pwdPath

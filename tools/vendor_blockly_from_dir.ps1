$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot

if (-not $env:BLOCKLY_DIST_DIR) {
  Write-Host "Set BLOCKLY_DIST_DIR to a directory containing Blockly dist files." -ForegroundColor Yellow
  Write-Host "Example:" -ForegroundColor Yellow
  Write-Host "  `$env:BLOCKLY_DIST_DIR = '.block2python\\blockly-12.4.1\\package'" -ForegroundColor Yellow
  Write-Host "  powershell -ExecutionPolicy Bypass -File tools/vendor_blockly_from_dir.ps1" -ForegroundColor Yellow
  Set-Location $pwdPath
  exit 1
}

$srcDir = $env:BLOCKLY_DIST_DIR
if (-not (Test-Path $srcDir)) {
  throw "BLOCKLY_DIST_DIR not found: $srcDir"
}

$outDir = Join-Path $repoRoot "assets\\blockly\\vendor"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $outDir "msg") | Out-Null

function Copy-Required($relPath) {
  $src = Join-Path $srcDir $relPath
  if (-not (Test-Path $src)) { throw "Missing file: $src" }
  $dest = Join-Path $outDir $relPath
  $destParent = Split-Path -Parent $dest
  New-Item -ItemType Directory -Force -Path $destParent | Out-Null
  Copy-Item -Force -Path $src -Destination $dest
}

Copy-Required "blockly_compressed.js"
Copy-Required "blocks_compressed.js"
Copy-Required "python_compressed.js"
Copy-Required "msg\\zh-hant.js"

Write-Host "Vendored files to: $outDir"

Set-Location $pwdPath

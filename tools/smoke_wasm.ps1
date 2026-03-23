param(
    [string]$WasmPath = $env:BLOCK2PYTHON_WASM_PATH,
    [string]$WasmtimeBin = $env:BLOCK2PYTHON_WASMTIME_BIN
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot
$env:PYTHONPATH = Join-Path $repoRoot "src"

if (-not $WasmPath) {
    $WasmPath = "assets/wasm/python.wasm"
}
if (-not $WasmtimeBin) {
    $localWasmtime = Join-Path $repoRoot ".block2python\tools\wasmtime\wasmtime.exe"
    if (Test-Path $localWasmtime) {
        $WasmtimeBin = $localWasmtime
    } else {
        $WasmtimeBin = "wasmtime"
    }
}

$env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
$env:BLOCK2PYTHON_WASM_PATH = $WasmPath
$env:BLOCK2PYTHON_WASMTIME_BIN = $WasmtimeBin

Write-Host "Running smoke test with wasm judge..."
Write-Host "BLOCK2PYTHON_WASM_PATH=$env:BLOCK2PYTHON_WASM_PATH"
Write-Host "BLOCK2PYTHON_WASMTIME_BIN=$env:BLOCK2PYTHON_WASMTIME_BIN"

$venvPy = Join-Path $repoRoot ".venv\Scripts\python.exe"
if (Test-Path $venvPy) {
    & $venvPy -m block2python.clients.cli.main
} else {
    Write-Host "Missing .venv. Run: tools/setup_dev_env.ps1"
    exit 1
}

Set-Location $pwdPath

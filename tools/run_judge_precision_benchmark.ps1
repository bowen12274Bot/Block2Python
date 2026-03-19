param(
    [int]$Runs = 30,
    [int]$WarnElapsedMs = 1800,
    [ValidateSet("auto", "inline", "tempfile", "stdin")]
    [string]$CodeMode = "auto",
    [int]$PrecisionMemoryLimitMB = 256,
    [int]$MemoryProbeLimitMB = 16,
    [switch]$Strict = $false
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
    $pythonExe = ".\\.venv\\Scripts\\python.exe"
    if (-not (Test-Path $pythonExe)) {
        Write-Host "FAIL virtual environment not found: $pythonExe" -ForegroundColor Red
        exit 1
    }

    $localWasmtime = ".block2python\\tools\\wasmtime\\wasmtime.exe"

    $args = @(
        "tools/judge_precision_benchmark.py",
        "--runs", "$Runs",
        "--warn-elapsed-ms", "$WarnElapsedMs",
        "--code-mode", "$CodeMode",
        "--precision-memory-limit-mb", "$PrecisionMemoryLimitMB",
        "--memory-probe-limit-mb", "$MemoryProbeLimitMB"
    )

    if (Test-Path $localWasmtime) {
        $args += @("--wasmtime-bin", $localWasmtime)
    }

    if ($Strict) {
        $args += "--strict"
    }

    & $pythonExe @args
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}

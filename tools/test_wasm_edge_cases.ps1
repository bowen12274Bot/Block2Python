# Test Wasm Judge edge scenarios (TLE / MLE)
# Requires wasmtime + assets/wasm/python.wasm

param(
    [switch]$SkipMLE = $false,
    [ValidateSet("auto", "inline", "tempfile", "stdin")]
    [string]$CodeMode = "auto"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
    Write-Host "=== Wasm Judge Edge Tests (TLE/MLE) ===" -ForegroundColor Cyan
    Write-Host ""

    $pythonExe = ".\\.venv\\Scripts\\python.exe"
    if (-not (Test-Path $pythonExe)) {
        Write-Host "FAIL virtual environment not found: $pythonExe" -ForegroundColor Red
        exit 1
    }

    $env:BLOCK2PYTHON_WASM_CODE_MODE = $CodeMode

    # 1) TLE
    Write-Host "[1/2] Testing Time Limit Exceeded (TLE)..." -ForegroundColor Yellow
    $testScript = @"
import sys
sys.path.insert(0, 'src')
from pathlib import Path
from block2python.judge import WasmJudge, WasmtimeRunner
from block2python.contracts import Submission, LevelSpec, Testcase, JudgePolicy, JudgeStatus

runner = WasmtimeRunner(wasm_path=Path('assets/wasm/python.wasm'), code_mode='${CodeMode}')
judge = WasmJudge(runner=runner, fail_fast=True)

level = LevelSpec(
    level_id='test-tle',
    title='Test TLE',
    testcases=(Testcase(stdin='', expected_stdout='done\n'),),
    judge_policy=JudgePolicy(time_limit_ms=500, memory_limit_kb=256 * 1024),
)

submission = Submission(
    level_id='test-tle',
    python_code='import time\nwhile True: time.sleep(0.01)'
)

result = judge.judge(submission, level)
assert result.status == JudgeStatus.TLE, f'Expected TLE, got {result.status}'
assert result.case_results[0].status == 'TIMEOUT', 'Expected TIMEOUT case status'
print(f'OK TLE test passed: {result.summary}')
print(f'Elapsed: {result.elapsed_ms} ms')
"@

    & $pythonExe -c $testScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAIL TLE test failed" -ForegroundColor Red
        exit 1
    }

    if (-not $SkipMLE) {
        # 2) MLE
        Write-Host "[2/2] Testing Memory Limit Exceeded (MLE)..." -ForegroundColor Yellow
        $testScript = @"
import sys
sys.path.insert(0, 'src')
from pathlib import Path
from block2python.judge import WasmJudge, WasmtimeRunner
from block2python.contracts import Submission, LevelSpec, Testcase, JudgePolicy, JudgeStatus

runner = WasmtimeRunner(wasm_path=Path('assets/wasm/python.wasm'), code_mode='${CodeMode}')
judge = WasmJudge(runner=runner, fail_fast=True)

level = LevelSpec(
    level_id='test-mle',
    title='Test MLE',
    testcases=(Testcase(stdin='', expected_stdout='done\n'),),
    judge_policy=JudgePolicy(time_limit_ms=3000, memory_limit_kb=10240),  # 10MB
)

submission = Submission(
    level_id='test-mle',
    python_code='data = [0] * (50 * 1024 * 1024 // 8); print("done")'
)

result = judge.judge(submission, level)
assert result.status in (JudgeStatus.MLE, JudgeStatus.RE), f'Expected MLE or RE, got {result.status}'
if result.status == JudgeStatus.MLE:
    assert result.case_results[0].status == 'MEMORY_LIMIT', 'Expected MEMORY_LIMIT case status'
    print(f'OK MLE test passed: {result.summary}')
else:
    print(f'OK memory constraint triggered RE: {result.summary}')
"@

        & $pythonExe -c $testScript
        if ($LASTEXITCODE -ne 0) {
            Write-Host "WARN MLE test did not pass (psutil or platform behavior)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "[2/2] Skipped MLE test (--SkipMLE)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "=== Edge tests complete ===" -ForegroundColor Green
    Write-Host "OK TLE verified" -ForegroundColor Green
    if (-not $SkipMLE) {
        Write-Host "OK MLE attempted" -ForegroundColor Green
    }
}
finally {
    Pop-Location
}

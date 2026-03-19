# Wasm Judge Verification Script
# Purpose: Verify wasmtime + python.wasm complete workflow, including AC/WA/TLE/MLE scenarios

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
    Write-Host "=== Wasm Judge Verification ===" -ForegroundColor Cyan
    Write-Host ""

    # 1. Check wasmtime
    Write-Host "[1/5] Checking wasmtime..." -ForegroundColor Yellow
    try {
        $wasmtimeVersion = & wasmtime --version 2>&1
        Write-Host "OK wasmtime installed: $wasmtimeVersion" -ForegroundColor Green
    } catch {
        Write-Host "FAIL wasmtime not found" -ForegroundColor Red
        Write-Host "Install: winget install BytecodeAlliance.Wasmtime" -ForegroundColor Yellow
        exit 1
    }

    # 2. Check python.wasm
    Write-Host "[2/5] Checking python.wasm..." -ForegroundColor Yellow
    $wasmPath = "assets\wasm\python.wasm"
    if (-not (Test-Path $wasmPath)) {
        Write-Host "FAIL python.wasm not found at $wasmPath" -ForegroundColor Red
        exit 1
    }
    Write-Host "OK python.wasm exists" -ForegroundColor Green

    # 3. Check Python environment
    Write-Host "[3/5] Checking Python environment..." -ForegroundColor Yellow
    $pythonExe = ".\.venv\Scripts\python.exe"
    if (-not (Test-Path $pythonExe)) {
        Write-Host "FAIL Virtual environment not found" -ForegroundColor Red
        exit 1
    }
    Write-Host "OK Virtual environment ready" -ForegroundColor Green

    # 4. Test WasmJudge AC scenario
    Write-Host "[4/5] Testing WasmJudge (AC scenario)..." -ForegroundColor Yellow
    $env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
    
    $tempScript = New-TemporaryFile
    $tempScriptPath = "$tempScript.py"
    Move-Item $tempScript.FullName $tempScriptPath -Force
    
    Set-Content -Path $tempScriptPath -Value @'
import sys
sys.path.insert(0, 'src')
from pathlib import Path
from block2python.judge import WasmJudge, WasmtimeRunner
from block2python.contracts import Submission, LevelSpec, Testcase, JudgePolicy, JudgeStatus

runner = WasmtimeRunner(wasm_path=Path('assets/wasm/python.wasm'))
judge = WasmJudge(runner=runner, fail_fast=True)

level = LevelSpec(
    level_id='test-ac',
    title='Test AC',
    testcases=(
        Testcase(stdin='1 2\n', expected_stdout='3\n'),
    ),
    judge_policy=JudgePolicy(time_limit_ms=5000, memory_limit_kb=256*1024)
)

submission = Submission(level_id='test-ac', python_code='a, b = map(int, input().split())\nprint(a + b)')
result = judge.judge(submission, level)

if result.status != JudgeStatus.AC:
    print(f'FAIL Expected AC, got {result.status}')
    print(f'Summary: {result.summary}')
    for i, case in enumerate(result.case_results):
        print(f'Case {i}: status={case.status}')
        if case.stderr:
            print(f'  stderr: {case.stderr[:200]}')
    import sys
    sys.exit(1)

print(f'OK AC Test Passed: {result.summary}')
'@
    
    & $pythonExe $tempScriptPath
    $testResult = $LASTEXITCODE
    Remove-Item $tempScriptPath -Force
    
    if ($testResult -ne 0) {
        Write-Host "FAIL AC test failed" -ForegroundColor Red
        exit 1
    }

    # 5. Test WasmJudge WA scenario
    Write-Host "[5/5] Testing WasmJudge (WA scenario)..." -ForegroundColor Yellow
    
    $tempScript = New-TemporaryFile
    $tempScriptPath = "$tempScript.py"
    Move-Item $tempScript.FullName $tempScriptPath -Force
    
    Set-Content -Path $tempScriptPath -Value @'
import sys
sys.path.insert(0, 'src')
from pathlib import Path
from block2python.judge import WasmJudge, WasmtimeRunner
from block2python.contracts import Submission, LevelSpec, Testcase, JudgePolicy, JudgeStatus

runner = WasmtimeRunner(wasm_path=Path('assets/wasm/python.wasm'))
judge = WasmJudge(runner=runner, fail_fast=True)

level = LevelSpec(
    level_id='test-wa',
    title='Test WA',
    testcases=(
        Testcase(stdin='1 2\n', expected_stdout='3\n'),
    ),
    judge_policy=JudgePolicy(time_limit_ms=1000)
)

submission = Submission(level_id='test-wa', python_code='print(999)')
result = judge.judge(submission, level)

assert result.status == JudgeStatus.WA, f'Expected WA, got {result.status}'
print(f'OK WA Test Passed: {result.summary}')
'@
    
    & $pythonExe $tempScriptPath
    $testResult = $LASTEXITCODE
    Remove-Item $tempScriptPath -Force
    
    if ($testResult -ne 0) {
        Write-Host "FAIL WA test failed" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "=== All Verifications Passed ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your Wasm Judge environment is fully configured!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run full tests: pytest -v" -ForegroundColor White
    Write-Host "  2. Test TLE/MLE: .\tools\verify_wasm_limits.ps1" -ForegroundColor White
    Write-Host "  3. Start CLI check: python -m block2python.clients.cli.main" -ForegroundColor White
    Write-Host ""

} finally {
    Pop-Location
}


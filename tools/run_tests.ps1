# Run pytest test suite
# Usage: .\tools\run_tests.ps1

param(
    [string]$Pattern = "",
    [switch]$Coverage = $false,
    [switch]$Verbose = $false,
    [string]$Marker = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

Push-Location $repoRoot

try {
    Write-Host "=== Block2Python Test Runner ===" -ForegroundColor Cyan
    
    # Check if venv exists
    if (-not (Test-Path ".\.venv\Scripts\python.exe")) {
        Write-Host "ERROR: Virtual environment not found at .\.venv\" -ForegroundColor Red
        Write-Host "Please run: python -m venv .venv" -ForegroundColor Yellow
        exit 1
    }
    
    # Check if pytest is installed
    $pytestCheck = & .\.venv\Scripts\python.exe -m pytest --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: pytest not installed" -ForegroundColor Red
        Write-Host "Please run: .\.venv\Scripts\python.exe -m pip install -e '.[dev]'" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Python: " -NoNewline
    & .\.venv\Scripts\python.exe --version
    Write-Host "Pytest: " -NoNewline
    Write-Host $pytestCheck
    Write-Host ""
    
    # Build pytest command
    $pytestArgs = @()
    
    if ($Verbose) {
        $pytestArgs += "-v"
    }
    
    if ($Coverage) {
        $pytestArgs += "--cov"
        $pytestArgs += "--cov-report=html"
        $pytestArgs += "--cov-report=term-missing"
    }
    
    if ($Marker) {
        $pytestArgs += "-m"
        $pytestArgs += $Marker
    }
    
    if ($Pattern) {
        $pytestArgs += $Pattern
    }
    
    Write-Host "Running: pytest $($pytestArgs -join ' ')" -ForegroundColor Green
    Write-Host ""
    
    & .\.venv\Scripts\python.exe -m pytest @pytestArgs
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "✓ All tests passed!" -ForegroundColor Green
        
        if ($Coverage) {
            Write-Host ""
            Write-Host "Coverage report generated at: htmlcov\index.html" -ForegroundColor Cyan
            $openReport = Read-Host "Open coverage report? (y/n)"
            if ($openReport -eq "y") {
                Start-Process "htmlcov\index.html"
            }
        }
    } else {
        Write-Host ""
        Write-Host "✗ Tests failed with exit code: $exitCode" -ForegroundColor Red
    }
    
    exit $exitCode
    
} finally {
    Pop-Location
}

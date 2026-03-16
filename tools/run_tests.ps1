<<<<<<< HEAD
# Run pytest test suite
=======
﻿# Run pytest test suite
>>>>>>> main
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
<<<<<<< HEAD
    
    # Check if venv exists
=======

>>>>>>> main
    if (-not (Test-Path ".\.venv\Scripts\python.exe")) {
        Write-Host "ERROR: Virtual environment not found at .\.venv\" -ForegroundColor Red
        Write-Host "Please run: python -m venv .venv" -ForegroundColor Yellow
        exit 1
    }
<<<<<<< HEAD
    
    # Check if pytest is installed
=======

>>>>>>> main
    $pytestCheck = & .\.venv\Scripts\python.exe -m pytest --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: pytest not installed" -ForegroundColor Red
        Write-Host "Please run: .\.venv\Scripts\python.exe -m pip install -e '.[dev]'" -ForegroundColor Yellow
        exit 1
    }
<<<<<<< HEAD
    
=======

>>>>>>> main
    Write-Host "Python: " -NoNewline
    & .\.venv\Scripts\python.exe --version
    Write-Host "Pytest: " -NoNewline
    Write-Host $pytestCheck
    Write-Host ""
<<<<<<< HEAD
    
    # Build pytest command
    $pytestArgs = @()
    
    if ($Verbose) {
        $pytestArgs += "-v"
    }
    
=======

    $pytestTempRoot = Join-Path $env:LOCALAPPDATA "Temp\Block2Python\pytest"
    New-Item -ItemType Directory -Path $pytestTempRoot -Force | Out-Null
    $pytestBaseTemp = Join-Path $pytestTempRoot ("run-" + [guid]::NewGuid().ToString("N"))

    $pytestArgs = @("--basetemp", $pytestBaseTemp)

    if ($Verbose) {
        $pytestArgs += "-v"
    }

>>>>>>> main
    if ($Coverage) {
        $pytestArgs += "--cov"
        $pytestArgs += "--cov-report=html"
        $pytestArgs += "--cov-report=term-missing"
    }
<<<<<<< HEAD
    
=======

>>>>>>> main
    if ($Marker) {
        $pytestArgs += "-m"
        $pytestArgs += $Marker
    }
<<<<<<< HEAD
    
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
    
=======

    if ($Pattern) {
        $patternArgs = $Pattern -split '\s+' | Where-Object { $_ }
        $pytestArgs += $patternArgs
    }

    Write-Host "Using pytest temp directory: $pytestBaseTemp" -ForegroundColor DarkCyan
    Write-Host "Running: pytest $($pytestArgs -join ' ')" -ForegroundColor Green
    Write-Host ""

    & .\.venv\Scripts\python.exe -m pytest @pytestArgs

    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "All tests passed." -ForegroundColor Green

        if ($Coverage) {
            Write-Host ""
            Write-Host "Coverage report generated at: htmlcov\index.html" -ForegroundColor Cyan
        }
    } else {
        Write-Host ""
        Write-Host "Tests failed with exit code: $exitCode" -ForegroundColor Red
    }

    exit $exitCode

>>>>>>> main
} finally {
    Pop-Location
}

param(
    [int]$CovFailUnder = 70,
    [switch]$SkipMLE = $false,
    [switch]$RequireBlocklyVendor = $false
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pwdPath = (Get-Location).Path
Set-Location $repoRoot

$failed = $false

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "=== $Name ===" -ForegroundColor Cyan
    try {
        & $Action
        Write-Host "PASS: $Name" -ForegroundColor Green
    } catch {
        $script:failed = $true
        Write-Host "FAIL: $Name" -ForegroundColor Red
        Write-Host $_ -ForegroundColor Yellow
    }
}

function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )
    if (-not (Test-Path $RelativePath)) {
        throw "Missing required asset: $RelativePath"
    }
}

try {
    $pythonExe = ".\.venv\Scripts\python.exe"
    if (-not (Test-Path $pythonExe)) {
        throw "Missing virtual environment python: $pythonExe"
    }

    Invoke-Step -Name "Key Assets Check" -Action {
        $requiredAssets = @(
            "assets/levels/index.yaml",
            "assets/levels/judge-precision-sum-series.yaml",
            "assets/game_content/index.yaml",
            "assets/blockly/index.html",
            "assets/wasm/python.wasm"
        )

        $optionalBlocklyVendorAssets = @(
            "assets/blockly/vendor/blockly_compressed.js",
            "assets/blockly/vendor/blocks_compressed.js",
            "assets/blockly/vendor/python_compressed.js",
            "assets/blockly/vendor/msg/zh-hant.js"
        )

        $missingAssets = @()

        foreach ($asset in $requiredAssets) {
            if (-not (Test-Path $asset)) {
                $missingAssets += $asset
            }
        }

        if ($missingAssets.Count -gt 0) {
            Write-Host "Missing assets:" -ForegroundColor Yellow
            foreach ($missing in $missingAssets) {
                Write-Host "  - $missing" -ForegroundColor Yellow
            }
            throw "Missing $($missingAssets.Count) required assets"
        }

        $missingOptionalBlocklyAssets = @()
        foreach ($asset in $optionalBlocklyVendorAssets) {
            if (-not (Test-Path $asset)) {
                $missingOptionalBlocklyAssets += $asset
            }
        }

        if ($missingOptionalBlocklyAssets.Count -gt 0) {
            if ($RequireBlocklyVendor) {
                Write-Host "Missing Blockly vendor assets (strict mode):" -ForegroundColor Yellow
                foreach ($missing in $missingOptionalBlocklyAssets) {
                    Write-Host "  - $missing" -ForegroundColor Yellow
                }
                throw "Missing $($missingOptionalBlocklyAssets.Count) required Blockly vendor assets"
            }

            Write-Host "Blockly vendor assets are missing; UI will run in placeholder mode." -ForegroundColor Yellow
            Write-Host "Use tools/sync_blockly_vendor.ps1 to install them." -ForegroundColor Yellow
        }
    }

    Invoke-Step -Name "Full Pytest + Coverage Gate" -Action {
        & $pythonExe -m pytest --cov=src/block2python --cov-report=term-missing --cov-report=html --cov-fail-under=$CovFailUnder
        if ($LASTEXITCODE -ne 0) {
            throw "pytest failed or coverage below $CovFailUnder"
        }
    }

    Invoke-Step -Name "Judge Verify Script" -Action {
        & "$PSScriptRoot\verify_wasm_env.ps1"
        if ($LASTEXITCODE -ne 0) {
            throw "verify_wasm_env.ps1 failed"
        }
    }

    Invoke-Step -Name "Judge Edge Script" -Action {
        if ($SkipMLE) {
            & "$PSScriptRoot\verify_wasm_limits.ps1" -SkipMLE
        } else {
            & "$PSScriptRoot\verify_wasm_limits.ps1"
        }

        if ($LASTEXITCODE -ne 0) {
            throw "verify_wasm_limits.ps1 failed"
        }
    }

    Write-Host ""
    if ($failed) {
        Write-Host "Project gate finished with failures." -ForegroundColor Red
        exit 1
    }

    Write-Host "Project gate passed. Assets, coverage, and judge checks are all green." -ForegroundColor Green
    exit 0
}
finally {
    Set-Location $pwdPath
}

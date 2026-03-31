param(
  [int]$CaseCount = 80
)

$ErrorActionPreference = "Stop"

$sourceRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = "C:/Temp/cf_group01_rect_scan_testlib"
$testlibDir = Join-Path $sourceRoot "testlib"

$headerPath = Join-Path $testlibDir "testlib.h"
if (-not (Test-Path $headerPath)) {
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MikeMirzayanov/testlib/master/testlib.h" -OutFile $headerPath
}

if (Test-Path $buildRoot) {
  Remove-Item -Recurse -Force $buildRoot
}
New-Item -ItemType Directory -Path $buildRoot | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildRoot "testlib") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildRoot "solutions") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildRoot "tests/generated") | Out-Null

Copy-Item (Join-Path $sourceRoot "testlib/testlib.h") (Join-Path $buildRoot "testlib/testlib.h") -Force
Copy-Item (Join-Path $sourceRoot "testlib/generator.cpp") (Join-Path $buildRoot "testlib/generator.cpp") -Force
Copy-Item (Join-Path $sourceRoot "testlib/validator.cpp") (Join-Path $buildRoot "testlib/validator.cpp") -Force
Copy-Item (Join-Path $sourceRoot "testlib/checker.cpp") (Join-Path $buildRoot "testlib/checker.cpp") -Force
Copy-Item (Join-Path $sourceRoot "solutions/solution.cpp") (Join-Path $buildRoot "solutions/solution.cpp") -Force
Copy-Item (Join-Path $sourceRoot "solutions/brute.cpp") (Join-Path $buildRoot "solutions/brute.cpp") -Force

g++.exe -O2 -std=c++17 (Join-Path $buildRoot "testlib/generator.cpp") -o (Join-Path $buildRoot "testlib/generator.exe")
g++.exe -O2 -std=c++17 (Join-Path $buildRoot "testlib/validator.cpp") -o (Join-Path $buildRoot "testlib/validator.exe")
g++.exe -O2 -std=c++17 (Join-Path $buildRoot "testlib/checker.cpp") -o (Join-Path $buildRoot "testlib/checker.exe")
g++.exe -O2 -std=c++17 (Join-Path $buildRoot "solutions/solution.cpp") -o (Join-Path $buildRoot "solutions/solution.exe")
g++.exe -O2 -std=c++17 (Join-Path $buildRoot "solutions/brute.cpp") -o (Join-Path $buildRoot "solutions/brute.exe")

$gen = Join-Path $buildRoot "testlib/generator.exe"
$val = Join-Path $buildRoot "testlib/validator.exe"
$chk = Join-Path $buildRoot "testlib/checker.exe"
$sol = Join-Path $buildRoot "solutions/solution.exe"
$bru = Join-Path $buildRoot "solutions/brute.exe"
$work = Join-Path $buildRoot "tests/generated"

$total = 0
$valOk = 0
$duelOk = 0
$checkerOk = 0

for ($i = 1; $i -le $CaseCount; $i++) {
  $total++

  $inFile = Join-Path $work ("{0:D3}.in" -f $i)
  $ansFile = Join-Path $work ("{0:D3}.ans" -f $i)
  $oufFile = Join-Path $work ("{0:D3}.ouf" -f $i)

  $cmdLine = '"' + $gen + '" --low=1 --high=1000000000 ' + $i + ' > "' + $inFile + '"'
  cmd.exe /c $cmdLine | Out-Null

  Get-Content -Raw $inFile | & $val | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "validator failed on case $i"
  }
  $valOk++

  $inputText = Get-Content -Raw $inFile
  $solOut = $inputText | & $sol
  $bruteOut = $inputText | & $bru
  if ($solOut -ne $bruteOut) {
    throw "duel mismatch on case $i"
  }
  $duelOk++

  [System.IO.File]::WriteAllText($ansFile, $solOut, (New-Object System.Text.UTF8Encoding($false)))
  [System.IO.File]::WriteAllText($oufFile, $solOut, (New-Object System.Text.UTF8Encoding($false)))

  & $chk $inFile $ansFile $oufFile | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "checker rejected correct output on case $i"
  }
  $checkerOk++
}

$badIn = Join-Path $work "bad_non_positive.in"
[System.IO.File]::WriteAllText($badIn, "0`n5`n", (New-Object System.Text.UTF8Encoding($false)))
Get-Content -Raw $badIn | & $val | Out-Null
$invalidInputRejected = ($LASTEXITCODE -ne 0)

$probeIn = Join-Path $work "001.in"
$probeAns = Join-Path $work "001.ans"
$probeWrong = Join-Path $work "001.wrong"
[System.IO.File]::WriteAllText($probeWrong, "0 0`n", (New-Object System.Text.UTF8Encoding($false)))
& $chk $probeIn $probeAns $probeWrong | Out-Null
$wrongOutputRejected = ($LASTEXITCODE -ne 0)

Write-Host "TOTAL=$total"
Write-Host "VALIDATOR_OK=$valOk"
Write-Host "DUEL_OK=$duelOk"
Write-Host "CHECKER_OK=$checkerOk"
Write-Host "INVALID_INPUT_REJECTED=$invalidInputRejected"
Write-Host "WRONG_OUTPUT_REJECTED=$wrongOutputRejected"

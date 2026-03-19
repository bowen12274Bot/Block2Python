$ErrorActionPreference = "Stop"

$python = ".\.venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    throw "Virtualenv python not found at $python"
}

$env:PYTHONPATH = (Resolve-Path "src").Path

$payload = @(
    '{"action":{"action_type":"advance","payload":{}}}',
    '{"action":{"action_type":"advance","payload":{}}}',
    '{"action":{"action_type":"advance","payload":{}}}'
) -join [Environment]::NewLine

$payload = $payload + [Environment]::NewLine

$payload | & $python -m block2python.integration.bridge_stdio.server

# Block2Python 快速開始

- 版本：0.1.0
- 更新日期：2026-03-20

這份文件提供目前專案最短、最直覺的啟動路徑。
如果你需要更完整的環境設定、Wasm judge 或 Blockly vendor 說明，請看 `docs/contributing/environment_setup.md`。

## 先做這四件事

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
powershell -ExecutionPolicy Bypass -File tools/run_godot_client.ps1
.\tools\run_tests.ps1
.\tools\run_project_gate.ps1
```

意思分別是：

- `setup_dev_env.ps1`
  把 `.venv`、Godot、Wasmtime、Blockly vendor 都建好。
- `run_godot_client.ps1`
  啟動目前主 client。
- `run_tests.ps1`
  日常開發時手動跑 pytest。
- `run_project_gate.ps1`
  收尾前跑完整檢查。

## 1. 建立開發環境

建議直接使用工具腳本：

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
```

如果要手動建立：

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
```

## 2. 啟動主 client

目前主入口是 Godot client：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_godot_client.ps1
```

如果需要 console 版 Godot：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_godot_client.ps1 -Console
```

## 3. 其他入口

CLI client：

```powershell
.\.venv\Scripts\python.exe -m block2python.clients.cli.main
```

Bridge server：

```powershell
.\.venv\Scripts\python.exe -m block2python.integration.bridge_stdio.server
```

Legacy PySide6 client：

```powershell
.\tools\legacy\run_pyside6_client.ps1
```

## 4. Judge 模式

使用 CLI client 時，可以用環境變數切換 judge：

```powershell
$env:BLOCK2PYTHON_JUDGE_MODE = "stub"
.\.venv\Scripts\python.exe -m block2python.clients.cli.main
```

```powershell
$env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
.\.venv\Scripts\python.exe -m block2python.clients.cli.main
```

## 5. 測試與 Smoke

執行測試：

```powershell
.\.venv\Scripts\python.exe -m pytest
```

常用工具：

```powershell
.\tools\run_tests.ps1
.\tools\smoke_bridge.ps1
.\tools\smoke_wasm.ps1
.\tools\verify_wasm_env.ps1
.\tools\verify_wasm_limits.ps1
.\tools\reset_progress.ps1
```

## 6. Legacy 工具

如果你需要舊流程：

```powershell
.\tools\legacy\run_cli_demo.ps1
.\tools\legacy\run_pyside6_client.ps1
.\tools\legacy\run_game_session_demo.ps1
```

## 7. 相關文件

- `docs/contributing/environment_setup.md`
- `docs/contributing/developer_workflow.md`
- `tests/README.md`
- `tools/README.md`

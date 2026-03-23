# Tests

這個目錄放的是 Block2Python 的 pytest 測試與少量 smoke script。

## 1. 測試分類

- Unit tests
  驗證單一模組或單一類別的行為。
- Integration tests
  驗證多個模組串接後的流程。
- Wasm-dependent tests
  需要 `assets/wasm/python.wasm` 與 `wasmtime`。
- Smoke scripts
  不一定走 pytest，主要用來做快速 sanity check。

## 2. 基本用法

安裝開發依賴：

```powershell
.\.venv\Scripts\python.exe -m pip install -e ".[dev]"
```

執行全部測試：

```powershell
.\.venv\Scripts\python.exe -m pytest
```

執行單一檔案：

```powershell
.\.venv\Scripts\python.exe -m pytest tests/test_game_session.py
```

執行單一測試：

```powershell
.\.venv\Scripts\python.exe -m pytest tests/test_game_session.py::test_game_session_walks_scene_and_challenge_flow
```

依 marker 執行：

```powershell
.\.venv\Scripts\python.exe -m pytest -m integration
.\.venv\Scripts\python.exe -m pytest -m requires_wasm -v
```

Coverage：

```powershell
.\.venv\Scripts\python.exe -m pytest --cov-report=html
Start-Process htmlcov/index.html
```

## 3. 常用工具腳本

```powershell
.\tools\run_tests.ps1
.\tools\smoke_bridge.ps1
.\tools\smoke_wasm.ps1
.\tools\verify_wasm_env.ps1
.\tools\verify_wasm_limits.ps1
```

Legacy smoke / demo：

```powershell
.\tools\legacy\run_cli_demo.ps1
.\tools\legacy\run_pyside6_client.ps1
.\tools\legacy\run_game_session_demo.ps1
```

## 4. 主要測試檔案

- `test_app_core.py`
  level_play / AppCore 相關行為。
- `test_game_session.py`
  `GameSession` 的 quest / scene / challenge flow。
- `test_game_content_loader.py`
  content loader 與資料組裝。
- `test_levels_loader.py`
  levels loader 與 schema 驗證。
- `test_judge_factory.py`
  judge 建立流程。
- `test_wasm_judge.py`
  Wasm judge 行為。
- `test_smoke_wasm_full.py`
  較完整的 Wasm smoke 驗證。
- `smoke_wasm_judge.py`
  不走 pytest 的 Wasm smoke script。

## 5. Wasm 測試需求

需要以下資源：

- `assets/wasm/python.wasm`
- `wasmtime` 可執行檔

如果環境不完整，部分 `requires_wasm` 測試可能會 skip，這是正常行為。

## 6. 相關文件

- `docs/contributing/developer_workflow.md`
- `docs/contributing/environment_setup.md`
- `docs/QUICKSTART.md`
- `tools/README.md`

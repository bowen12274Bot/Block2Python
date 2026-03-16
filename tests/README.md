# Tests

<<<<<<< HEAD
本資料夾存放所有自動化測試。

## 測試架構

- **Unit Tests**: 測試個別模組功能（`test_*.py`）
- **Integration Tests**: 測試跨模組整合（標記 `@pytest.mark.integration`）
- **Smoke Test**: 快速驗證核心流程（`smoke_wasm_judge.py`）

## 執行測試

### 安裝測試依賴

```powershell
# 使用 venv
.\.venv\Scripts\python.exe -m pip install -e ".[dev]"
```

### 執行所有測試

```powershell
# 使用 pytest
.\.venv\Scripts\python.exe -m pytest

# 或使用預設設定（包含 coverage）
.\.venv\Scripts\python.exe -m pytest -v
```

### 執行特定測試

```powershell
# 單一測試檔案
.\.venv\Scripts\python.exe -m pytest tests/test_wasm_judge.py

# 特定測試函數
.\.venv\Scripts\python.exe -m pytest tests/test_wasm_judge.py::TestWasmJudge::test_ac_status

# 測試標記
.\.venv\Scripts\python.exe -m pytest -m unit
```

### Coverage 報告

```powershell
# HTML 報告（自動產生於 htmlcov/）
.\.venv\Scripts\python.exe -m pytest --cov-report=html

# 開啟報告
Start-Process htmlcov/index.html
```

### 快速 Smoke Test（舊版）

```powershell
$env:PYTHONPATH = "src"
.\.venv\Scripts\python.exe tests/smoke_wasm_judge.py
```

## 測試檔案說明

| 檔案 | 說明 |
|------|------|
| `conftest.py` | pytest 配置與共用 fixtures |
| `test_judge_normalization.py` | 輸出正規化邏輯測試 |
| `test_wasm_judge.py` | WasmJudge 核心邏輯（用 fake runner） |
| `test_judge_factory.py` | Judge 工廠與環境變數配置測試 |
| `test_levels_loader.py` | 關卡載入與 judge_policy 解析測試 |
| `test_app_core.py` | AppCore 提交流程與狀態管理測試 |
| `smoke_wasm_judge.py` | 獨立 smoke 測試（不依賴 pytest） |

## CI/CD 整合

在 CI Pipeline 中建議：

```yaml
- name: Run tests
	run: |
		python -m pip install -e ".[dev]"
		python -m pytest --cov --cov-report=xml
```

## 需要 wasmtime 的測試

標記為 `@pytest.mark.requires_wasm` 的測試需要：
1. `python.wasm` 存在於 `assets/wasm/`
2. `wasmtime` 可執行

未配置時這些測試會被 skip。
=======
本資料夾存放 Block2Python 的自動化測試與少量輔助 smoke script。
>>>>>>> main

## 1. 測試策略

目前驗證原則是：

- `pytest` 是主要測試入口
- smoke script 是輔助驗證，不取代 `pytest`

## 2. 測試類型

- Unit tests：以單一模組或單一功能為主
- Integration tests：跨模組整合驗證，使用 `@pytest.mark.integration`
- Wasm-dependent tests：需要真實 `python.wasm` 與 `wasmtime`，使用 `@pytest.mark.requires_wasm`
- Smoke script：用於快速 sanity check 或 demo 前確認

## 3. 基本指令

### 安裝依賴

```powershell
.\.venv\Scripts\python.exe -m pip install -e ".[dev]"
```

### 執行全部測試

```powershell
.\.venv\Scripts\python.exe -m pytest
```

### 執行單一檔案或單一測試

```powershell
.\.venv\Scripts\python.exe -m pytest tests/test_wasm_judge.py
.\.venv\Scripts\python.exe -m pytest tests/test_wasm_judge.py::TestWasmJudge::test_ac_status
```

### 依 marker 篩選

```powershell
.\.venv\Scripts\python.exe -m pytest -m unit
.\.venv\Scripts\python.exe -m pytest -m integration
.\.venv\Scripts\python.exe -m pytest -m requires_wasm -v
```

### Coverage

```powershell
.\.venv\Scripts\python.exe -m pytest --cov-report=html
Start-Process htmlcov/index.html
```

## 4. Smoke scripts

以下腳本屬於輔助驗證：

```powershell
.\tools\run_demo.ps1
.\tools\run_ui.ps1
.\tools\run_wasm_smoke.ps1
```

另外也保留獨立 smoke 檔案：

```powershell
$env:PYTHONPATH = "src"
.\.venv\Scripts\python.exe tests/smoke_wasm_judge.py
```

建議用途：

- demo 展示前快速確認
- UI / Blockly 流程手動檢查
- Wasm judge 環境 sanity check

## 5. 目前主要測試檔

| 檔案 | 說明 |
|---|---|
| `conftest.py` | pytest 共用 fixtures 與測試環境設定 |
| `test_app_core.py` | AppCore 提交流程與解鎖行為 |
| `test_judge_factory.py` | judge 建立流程與環境變數 |
| `test_judge_normalization.py` | 輸出正規化 |
| `test_levels_loader.py` | levels loader、YAML / JSON 相容與 testcase 載入 |
| `test_wasm_judge.py` | WasmJudge 核心行為 |
| `test_smoke_wasm_full.py` | 需要真實 wasm 環境的整合驗證 |
| `smoke_wasm_judge.py` | 不走 pytest 的獨立 smoke script |

## 6. Wasm 測試前提

標記為 `requires_wasm` 的測試需要：

- `assets/wasm/python.wasm`
- `wasmtime` 可從 `PATH` 執行

若環境不完整，測試可能會被 skip，或相關 smoke script 失敗。

## 7. 相關文件

- `docs/contributing/developer_workflow.md`
- `docs/contributing/environment_setup.md`
- `docs/QUICKSTART.md`

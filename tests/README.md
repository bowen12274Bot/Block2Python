# Tests

<<<<<<< HEAD
<<<<<<< HEAD
本資料夾存放所有自動化測試。
=======
本資料夾存放 Block2Python 的自動化測試與少量輔助 smoke script。
>>>>>>> merge/judge_introduction_branch

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

<<<<<<< HEAD
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

=======
## 7. 相關文件

>>>>>>> merge/judge_introduction_branch
- `docs/contributing/developer_workflow.md`
- `docs/contributing/environment_setup.md`
- `docs/QUICKSTART.md`

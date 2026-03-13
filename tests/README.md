# Tests

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


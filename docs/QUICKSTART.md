<<<<<<< HEAD
# Block2Python 執行指南

## 快速啟動（3 步驟）

### 1. 安裝依賴

```powershell
# 建立虛擬環境（如果還沒有）
python -m venv .venv

# 啟動虛擬環境
.\.venv\Scripts\Activate.ps1

# 安裝專案（開發模式）
pip install -e ".[dev]"

# 或僅安裝基本依賴
pip install -e .
```

### 2. 選擇執行模式

#### 模式 A：Stub Judge（無需額外配置）

```powershell
# 直接執行 CLI
python -m block2python

# 或啟動 GUI
python -m block2python.ui
```

#### 模式 B：Wasm Judge（需要 python.wasm）

```powershell
# 1. 取得 python.wasm（參考 docs/WASM_SETUP.md）
# 2. 放到 assets/wasm/python.wasm
# 3. 安裝 wasmtime（參考 docs/WASM_SETUP.md）

# 執行（會自動偵測 wasm 並切換）
python -m block2python

# 或使用環境變數強制 wasm 模式
$env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
python -m block2python
```

### 3. 驗證設定

```powershell
# 執行測試確保一切正常
pytest

# 快速 smoke test
python tests/smoke_wasm_judge.py
```

## 詳細執行選項

### CLI 模式

```powershell
# 使用預設 demo 關卡
python -m block2python

# 使用自訂關卡目錄
$env:BLOCK2PYTHON_LEVELS_DIR = "path\to\levels"
python -m block2python
```

### GUI 模式

```powershell
# 啟動 Qt6 GUI
python -m block2python.ui

# 或使用工具腳本
.\tools\run_ui.ps1
```

### 環境變數配置

```powershell
# Judge 模式
$env:BLOCK2PYTHON_JUDGE_MODE = "auto"     # auto (預設) | stub | wasm

# Wasm 配置
$env:BLOCK2PYTHON_WASM_PATH = "assets\wasm\python.wasm"
$env:BLOCK2PYTHON_WASMTIME_BIN = "wasmtime"
$env:BLOCK2PYTHON_WASM_CODE_MODE = "auto"    # auto | inline | tempfile | stdin

# Judge 行為
$env:BLOCK2PYTHON_JUDGE_FAIL_FAST = "true"  # true | false

# 關卡目錄
$env:BLOCK2PYTHON_LEVELS_DIR = "assets\levels"
```

## 開發工具腳本

專案提供了多個 PowerShell 腳本簡化開發：

```powershell
# 設定開發環境
.\tools\setup_dev_env.ps1

# 執行 UI
.\tools\run_ui.ps1

# 執行 CLI demo
.\tools\run_demo.ps1

# Wasm smoke test
.\tools\run_wasm_smoke.ps1

# 重設進度
.\tools\reset_progress.ps1
```

## 常見執行流程

### 開發新 Judge 功能

```powershell
# 1. 寫測試
# tests/test_my_feature.py

# 2. 執行測試（TDD）
pytest tests/test_my_feature.py -v

# 3. 實作功能
# src/block2python/judge/...

# 4. 驗證
pytest

# 5. 手動測試
python -m block2python
```

### 新增關卡

```powershell
# 1. 建立關卡 JSON
# assets/levels/my-level.json

# 2. 更新 index.json
# assets/levels/index.json

# 3. 測試載入
python -m block2python

# 4. 重設進度重新測試
.\tools\reset_progress.ps1
```

## 測試執行詳細說明

### 執行所有測試

```powershell
# 標準模式
pytest

# 詳細輸出
pytest -v

# 顯示 print 輸出
pytest -s

# 僅執行失敗的測試
pytest --lf

# 停在第一個失敗
pytest -x
```

### Coverage 報告

```powershell
# 自動產生（pyproject.toml 已配置）
pytest

# HTML 報告
pytest --cov-report=html
Start-Process htmlcov/index.html
```

### 測試標記

```powershell
# 僅 unit tests
pytest -m unit

# 僅 integration tests
pytest -m integration

# 跳過需要 wasm 的測試
pytest -m "not requires_wasm"
```

## 除錯技巧

### Judge 模式除錯

```powershell
# 強制 stub 模式
$env:BLOCK2PYTHON_JUDGE_MODE = "stub"
python -m block2python

# 強制 wasm 模式並查看錯誤
$env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
python -m block2python
```

### 查看 Judge 選用資訊

```powershell
# CLI 啟動時會顯示：
# judge=StubJudge(auto fallback; wasm not found: ...)
# 或
# judge=WasmJudge wasm=assets\wasm\python.wasm wasmtime=wasmtime code_mode=auto
```

### 驗證 wasm 設定

```powershell
# 快速驗證（建議）
.\tools\verify_wasm_setup.ps1

# 邊界場景驗證（TLE / MLE）
.\tools\test_wasm_edge_cases.ps1
```

### UI 回饋除錯

GUI 送出後，feedback 區域會顯示：
- Judge backend 資訊
- 執行耗時 (`judge_elapsed_ms`)
- stderr 輸出
- 每筆 case 的 exit_code

## 效能建議

### 開發時

- 使用 `StubJudge`（快速回饋）
- 或設定較短的 `time_limit_ms`

### 實際評測時

- 使用 `WasmJudge`
- 調整 `time_limit_ms` 依題目複雜度
- 考慮關閉 `fail_fast` 看完整測資執行結果

## 疑難排解

### "PySide6 is not installed"

```powershell
pip install PySide6
```

### "wasmtime binary not found"

```powershell
# 安裝 wasmtime（參考 docs/WASM_SETUP.md）
scoop install wasmtime

# 或設定路徑
$env:BLOCK2PYTHON_WASMTIME_BIN = "C:\path\to\wasmtime.exe"
```

### 測試失敗

```powershell
# 確認環境
pytest --version
python --version

# 重新安裝
pip install -e ".[dev]" --force-reinstall

# 清除快取
pytest --cache-clear
```

### 進度異常

```powershell
# 刪除進度檔案
.\tools\reset_progress.ps1

# 或手動刪除
Remove-Item .block2python\progress.json
```

## 完整開發週期範例

```powershell
# 1. 初始化
git clone <repo>
cd Block2Python
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[dev]"

# 2. 執行測試確認環境
pytest

# 3. 開發功能
# ... 編輯程式碼 ...

# 4. 測試
pytest tests/test_my_feature.py -v

# 5. 手動驗證
python -m block2python

# 6. GUI 測試
python -m block2python.ui

# 7. 提交前最終檢查
pytest --cov
```
=======
# Block2Python 快速啟動

- 文件版本：1.0.0
- 更新日期：2026-03-11
- 這份文件只保留最短路徑：建立環境、啟動應用、切換 judge 模式、執行基本驗證。較完整的本機環境、Blockly vendor、Wasm judge 安裝與驗證，請看：

- `docs/contributing/environment_setup.md`

## 1. 建立開發環境

建議直接使用專案腳本：

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
```

若要手動建立：

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
```

## 2. 啟動 CLI / GUI

### CLI

```powershell
.\.venv\Scripts\python.exe -m block2python
```

### GUI

```powershell
.\.venv\Scripts\python.exe -m block2python.ui
```

## 3. Judge 模式

### 預設自動模式

```powershell
.\.venv\Scripts\python.exe -m block2python
```

- 若找到 `assets/wasm/python.wasm` 且 `wasmtime` 可執行，會使用 `WasmJudge`
- 否則回退到 `StubJudge`

### 強制 stub 模式

```powershell
$env:BLOCK2PYTHON_JUDGE_MODE = "stub"
.\.venv\Scripts\python.exe -m block2python
```

### 強制 wasm 模式

```powershell
$env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
.\.venv\Scripts\python.exe -m block2python
```

## 4. 題庫位置

預設題庫目錄：

```powershell
assets\levels
```

目前主題庫已統一為 YAML：

- `assets/levels/index.yaml`
- `assets/levels/*.yaml`

若要切換題庫路徑：

```powershell
$env:BLOCK2PYTHON_LEVELS_DIR = "path\to\levels"
.\.venv\Scripts\python.exe -m block2python
```

## 5. 基本驗證

```powershell
.\.venv\Scripts\python.exe -m pytest
```

若要跑 Wasm 相關 smoke test：

```powershell
.\tools\run_wasm_smoke.ps1
```

## 6. 常用腳本

```powershell
.\tools\run_demo.ps1
.\tools\run_ui.ps1
.\tools\run_tests.ps1
.\tools\verify_wasm_setup.ps1
.\tools\test_wasm_edge_cases.ps1
.\tools\reset_progress.ps1
```

## 7. 下一步

- 題庫格式：`docs/specs/levels_schema_v0_1.md`
- 環境與 Wasm 設定：`docs/contributing/environment_setup.md`
- 測試說明：`tests/README.md`
- 協作與提交流程：`docs/contributing.md`
>>>>>>> main

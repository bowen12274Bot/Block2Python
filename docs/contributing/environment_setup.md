# 開發環境與本機資料

- 文件版本：0.2.0
- 更新日期：2026-03-11

本文件整合原本分散的環境設定、`python.wasm` 取得方式、Wasm judge 驗證腳本，以及 Blockly vendor 與本機資料說明。

## 1. Python 開發環境（標準：`.venv`）

本專案標準 Python 環境是 repo 根目錄的 `.venv`。

### 1.1 建立與安裝

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
```

或直接使用腳本：

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
```

### 1.2 啟動

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

### 1.3 依賴管理

目前專案依賴以 `pyproject.toml` 為準，至少包含：

- `PySide6`
- `PyYAML`
- `psutil`
- `pytest`
- `pytest-cov`

若 `.venv` 缺少依賴，重新執行：

```powershell
.\.venv\Scripts\python.exe -m pip install -e ".[dev]"
```

## 2. Wasm Judge 環境

### 2.1 安裝 Wasmtime

#### Windows / winget

```powershell
winget install BytecodeAlliance.Wasmtime
```

#### Windows / Chocolatey

```powershell
choco install wasmtime
```

#### 手動下載

1. 前往 `https://github.com/bytecodealliance/wasmtime/releases`
2. 下載 Windows zip
3. 將 `wasmtime.exe` 加入 `PATH`

驗證：

```powershell
wasmtime --version
```

### 2.2 取得 `python.wasm`

建議放在：

```powershell
assets\wasm\python.wasm
```

目前文件與腳本預設使用該位置，也可改用環境變數覆寫：

```powershell
$env:BLOCK2PYTHON_WASM_PATH = "D:\tools\python.wasm"
```

### 2.3 重要環境變數

```powershell
$env:BLOCK2PYTHON_JUDGE_MODE = "auto"     # auto | stub | wasm
$env:BLOCK2PYTHON_WASM_PATH = "assets\wasm\python.wasm"
$env:BLOCK2PYTHON_WASMTIME_BIN = "wasmtime"
$env:BLOCK2PYTHON_WASM_CODE_MODE = "auto" # auto | inline | tempfile | stdin
$env:BLOCK2PYTHON_JUDGE_FAIL_FAST = "true"
```

### 2.4 `BLOCK2PYTHON_WASM_CODE_MODE`

- `auto`：依序嘗試 `inline -> tempfile -> stdin`
- `inline`：直接用 `-c`
- `tempfile`：將 submission 寫成暫存檔，適合 Windows fallback
- `stdin`：以 `python -` 與 wrapper 執行

## 3. Wasm Judge 驗證與測試

### 3.1 一鍵驗證

```powershell
.\tools\verify_wasm_setup.ps1
```

驗證項目包括：

- `wasmtime` 是否可用
- `python.wasm` 是否存在
- Python 依賴是否完整
- WasmJudge 的 AC / WA 基本行為

### 3.2 Edge cases

```powershell
.\tools\test_wasm_edge_cases.ps1
```

若只想先跳過 MLE：

```powershell
.\tools\test_wasm_edge_cases.ps1 -SkipMLE
```

### 3.3 Pytest

```powershell
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m pytest -m requires_wasm -v
```

## 4. Blockly dist

UI 使用 `QWebEngineView` 載入 Blockly，因此 `assets/blockly/vendor/` 是必要資產。

### 4.1 從 URL 匯入

```powershell
$env:BLOCKLY_DIST_URL = "https://github.com/RaspberryPiFoundation/blockly/releases/download/blockly-v12.4.1/blockly-12.4.1.tgz"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

### 4.2 從本機 zip 匯入

```powershell
$env:BLOCKLY_DIST_ZIP = "C:\\path\\to\\blockly_dist.zip"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

### 4.3 從資料夾匯入

```powershell
$env:BLOCKLY_DIST_DIR = ".block2python\\blockly-12.4.1\\package"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly_from_dir.ps1
```

## 5. 本機資料與重置

不進版控的本機資料主要放在 `.block2python/`。

常見內容：

- `.block2python/progress.json`
- Blockly 匯入過程中的暫存檔
- 本機測試產生的中間資源

重置進度：

```powershell
.\tools\reset_progress.ps1
```

## 6. 常見問題

### `PySide6 is not installed`

```powershell
.\.venv\Scripts\python.exe -m pip install PySide6
```

### `PyYAML is not installed`

```powershell
.\.venv\Scripts\python.exe -m pip install PyYAML
```

### `wasmtime binary not found`

1. 先確認 `wasmtime --version`
2. 再確認 `BLOCK2PYTHON_WASMTIME_BIN`

### 自動模式沒有啟用 WasmJudge

請確認：

- `assets/wasm/python.wasm` 存在
- `wasmtime` 在 `PATH` 中
- `BLOCK2PYTHON_JUDGE_MODE` 沒有被強制設為 `stub`

## 7. 相關文件

- `docs/QUICKSTART.md`
- `docs/specs/levels_schema_v0_1.md`
- `tests/README.md`

# 開發環境與本機資料

<<<<<<< HEAD
- 文件版本：0.3.0
- 更新日期：2026-03-15

本文件整合原本分散的環境設定、Godot 本機安裝位置、`python.wasm` 取得方式、Wasm judge 驗證腳本，以及 Blockly vendor 與本機資料說明。
=======
- 文件版本：0.2.0
- 更新日期：2026-03-11

本文件整合原本分散的環境設定、`python.wasm` 取得方式、Wasm judge 驗證腳本，以及 Blockly vendor 與本機資料說明。
>>>>>>> merge/judge_introduction_branch

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

<<<<<<< HEAD
這個腳本目前可做四件事：

- 建立 `.venv` 並安裝 Python 開發依賴
- 將 `Godot 4.6.1` 下載到不進版控的 `.block2python/godot/4.6.1/`
- 將 `wasmtime.exe` 下載到不進版控的 `.block2python/tools/wasmtime/`
- 可選擇額外下載 Blockly dist，並 vendor 到 `assets/blockly/vendor/`

若你只想配置 Python 環境、不下載 Godot / Wasmtime：

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1 -SkipGodot -SkipWasmtime
```

若你想一起下載 Blockly：

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1 -IncludeBlockly
```

若你手上已經有解壓好的 Blockly dist 目錄：

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1 -IncludeBlockly -BlocklyDistDir ".block2python\\vendor\\blockly-12.4.1\\package"
```

### 1.2 啟動

目前主線前端入口是 Godot。

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_godot_poc.ps1
```

若要用 console 版 Godot：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_godot_poc.ps1 -Console
```

舊 CLI / PySide6 啟動腳本仍保留在 `tools/legacy/`：

```powershell
powershell -ExecutionPolicy Bypass -File tools/legacy/run_demo.ps1
powershell -ExecutionPolicy Bypass -File tools/legacy/run_ui.ps1
```

### 1.3 Godot 本機位置

本專案建議將 Godot 放在不進版控的：

```powershell
.block2python\godot\4.6.1\
```

`tools/setup_dev_env.ps1` 會自動下載：

- `Godot_v4.6.1-stable_win64.exe`
- `Godot_v4.6.1-stable_win64_console.exe`

放到上述目錄。

### 1.4 Blockly 本機位置

本專案建議將 Blockly dist 的下載與解壓結果放在不進版控的：

```powershell
.block2python\downloads\blockly\12.4.1\
.block2python\vendor\blockly-12.4.1\package\
```

其中：

- `downloads/` 放原始下載檔
- `vendor/` 放解壓後的 dist
- 真正給專案載入的檔案仍同步到 `assets/blockly/vendor/`

### 1.5 Wasmtime 本機位置

本專案建議將 Wasmtime 放在不進版控的：

```powershell
.block2python\tools\wasmtime\
```

`tools/setup_dev_env.ps1` 會自動下載：

- `wasmtime.exe`

放到上述目錄。

### 1.6 依賴管理

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

=======
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

>>>>>>> merge/judge_introduction_branch
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
<<<<<<< HEAD
3. 將 `wasmtime.exe` 放到 `.block2python\tools\wasmtime\` 或加入 `PATH`
=======
3. 將 `wasmtime.exe` 加入 `PATH`
>>>>>>> merge/judge_introduction_branch

驗證：

```powershell
<<<<<<< HEAD
.block2python\tools\wasmtime\wasmtime.exe --version
=======
wasmtime --version
>>>>>>> merge/judge_introduction_branch
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
<<<<<<< HEAD
$env:BLOCK2PYTHON_WASMTIME_BIN = ".block2python\tools\wasmtime\wasmtime.exe"
=======
$env:BLOCK2PYTHON_WASMTIME_BIN = "wasmtime"
>>>>>>> merge/judge_introduction_branch
$env:BLOCK2PYTHON_WASM_CODE_MODE = "auto" # auto | inline | tempfile | stdin
$env:BLOCK2PYTHON_JUDGE_FAIL_FAST = "true"
```

### 2.4 `BLOCK2PYTHON_WASM_CODE_MODE`

- `auto`：依序嘗試 `inline -> tempfile -> stdin`
- `inline`：直接用 `-c`
- `tempfile`：將 submission 寫成暫存檔，適合 Windows fallback
- `stdin`：以 `python -` 與 wrapper 執行

<<<<<<< HEAD
### 2.5 Windows / Godot 實務建議

目前在本 repo 的 Godot quest-map / bridge 整合路徑上，較穩定的設定是：

```powershell
$env:BLOCK2PYTHON_WASM_CODE_MODE = "stdin"
```

原因是某些 Windows 環境下：

- `auto` 可能因 `tempfile` 路徑權限或策略切換造成不穩定
- Godot 啟動 subprocess 時，用 `stdin` 模式較容易得到一致結果

如果你是在 Godot 端驗證 `submit_level`，建議優先使用 `stdin`。

=======
>>>>>>> merge/judge_introduction_branch
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

<<<<<<< HEAD
如果同版本 archive 已經存在於：

```powershell
.block2python\downloads\blockly\12.4.1\
```

腳本會直接重用，不重複下載。

### 4.2 從本機 zip / tgz 匯入
=======
### 4.2 從本機 zip 匯入
>>>>>>> merge/judge_introduction_branch

```powershell
$env:BLOCKLY_DIST_ZIP = "C:\\path\\to\\blockly_dist.zip"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

### 4.3 從資料夾匯入

```powershell
$env:BLOCKLY_DIST_DIR = ".block2python\\blockly-12.4.1\\package"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

## 5. 本機資料與重置

不進版控的本機資料主要放在 `.block2python/`。

常見內容：

- `.block2python/progress.json`
<<<<<<< HEAD
- `.block2python/godot/4.6.1/`
- `.block2python/downloads/blockly/12.4.1/`
- `.block2python/vendor/blockly-12.4.1/`
=======
>>>>>>> merge/judge_introduction_branch
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

<<<<<<< HEAD
1. 先確認 `.block2python\tools\wasmtime\wasmtime.exe --version` 或 `wasmtime --version`
=======
1. 先確認 `wasmtime --version`
>>>>>>> merge/judge_introduction_branch
2. 再確認 `BLOCK2PYTHON_WASMTIME_BIN`

### 自動模式沒有啟用 WasmJudge

請確認：

- `assets/wasm/python.wasm` 存在
<<<<<<< HEAD
- `.block2python\tools\wasmtime\wasmtime.exe` 存在，或 `wasmtime` 在 `PATH` 中
=======
- `wasmtime` 在 `PATH` 中
>>>>>>> merge/judge_introduction_branch
- `BLOCK2PYTHON_JUDGE_MODE` 沒有被強制設為 `stub`

## 7. 相關文件

- `docs/QUICKSTART.md`
- `docs/specs/levels_schema_v0_1.md`
- `tests/README.md`

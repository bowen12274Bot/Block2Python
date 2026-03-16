<<<<<<< HEAD
<<<<<<< HEAD
# Block2Python 執行指南
=======
# Block2Python 快速啟動
>>>>>>> merge/judge_introduction_branch

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

<<<<<<< HEAD
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

=======
>>>>>>> merge/judge_introduction_branch
- 題庫格式：`docs/specs/levels_schema_v0_1.md`
- 環境與 Wasm 設定：`docs/contributing/environment_setup.md`
- 測試說明：`tests/README.md`
- 協作與提交流程：`docs/contributing.md`
<<<<<<< HEAD
>>>>>>> main
=======
>>>>>>> merge/judge_introduction_branch

# Python.wasm 取得與配置指南

## 什麼是 python.wasm？

`python.wasm` 是 Python 解釋器編譯成 WebAssembly 格式的二進位檔案，讓你可以在沙箱環境中安全執行學生的 Python 程式碼。

## 取得方式（推薦順序）

### 方式 1：Python.org 官方 WASI 建置（推薦）

Python 3.11+ 提供官方 WASI 建置：

```powershell
# 下載 Python 3.11+ WASI build
# 前往 https://www.python.org/downloads/
# 下載 "WebAssembly" 版本
```

或直接從 GitHub Actions 取得：
- https://github.com/python/cpython/actions (搜尋 "wasi")

### 方式 2：VMware Wasm Labs

VMware 提供預編譯的 Python.wasm：

```powershell
# 範例下載（版本號請依實際調整）
Invoke-WebRequest -Uri "https://github.com/vmware-labs/webassembly-language-runtimes/releases/download/python-3.11/python-3.11.wasm" -OutFile python.wasm
```

### 方式 3：Pyodide（較大但功能完整）

如果需要標準函式庫支援，可用 Pyodide：
- https://github.com/pyodide/pyodide/releases

## 安裝 Wasmtime

Wasmtime 是執行 .wasm 檔案的引擎：

### Windows (Scoop)
```powershell
scoop install wasmtime
```

### Windows (Chocolatey)
```powershell
choco install wasmtime
```

### Windows (手動)
1. 前往 https://github.com/bytecodealliance/wasmtime/releases
2. 下載 `wasmtime-vXX.X.X-x86_64-windows.zip`
3. 解壓並加入 PATH

### 驗證安裝
```powershell
wasmtime --version
```

## 專案配置

### 方法 A：放在專案內（推薦用於開發）

```powershell
# 在專案根目錄（Windows PowerShell）
New-Item -ItemType Directory -Path assets\wasm -Force | Out-Null

# 將 python.wasm 複製到此
Copy-Item "C:\path\to\python.wasm" "assets\wasm\python.wasm" -Force
```

專案會自動偵測 `assets/wasm/python.wasm`。

### 方法 B：使用環境變數

```powershell
$env:BLOCK2PYTHON_WASM_PATH = "D:\tools\python.wasm"
$env:BLOCK2PYTHON_WASMTIME_BIN = "C:\tools\wasmtime.exe"  # 如果不在 PATH
```

## 測試配置

```powershell
# 建議使用專案驗證腳本（已包含 Windows 相容 fallback）
.\tools\verify_wasm_setup.ps1

# 如需手動切換傳碼策略：
$env:BLOCK2PYTHON_WASM_CODE_MODE = "tempfile"  # auto|inline|tempfile|stdin
.\tools\verify_wasm_setup.ps1
```

## 環境變數完整列表

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `BLOCK2PYTHON_JUDGE_MODE` | `auto` | `auto`/`stub`/`wasm` |
| `BLOCK2PYTHON_WASM_PATH` | `assets/wasm/python.wasm` | python.wasm 路徑 |
| `BLOCK2PYTHON_WASMTIME_BIN` | `wasmtime` | wasmtime 執行檔 |
| `BLOCK2PYTHON_WASM_CODE_MODE` | `auto` | 程式碼傳遞模式：`auto`/`inline`/`tempfile`/`stdin` |
| `BLOCK2PYTHON_JUDGE_FAIL_FAST` | `true` | 是否在第一筆測資失敗時停止 |

`BLOCK2PYTHON_WASM_CODE_MODE` 建議：
- Windows: 優先使用 `auto` 或 `tempfile`
- `auto` 會依序嘗試 `inline -> tempfile -> stdin`
- `inline` 可能在 Windows 遇到 `//-c` 路徑解析問題，會由 `auto` 自動 fallback

## 常見問題

### Q: 我沒有 python.wasm，程式會壞嗎？
**A:** 不會。預設 `auto` 模式會自動回退到 `StubJudge`，不影響開發。

### Q: python.wasm 很大怎麼辦？
**A:** 正常。完整 Python 解釋器約 15-50 MB。可考慮：
- 放在 `.gitignore`（已預設忽略 `assets/wasm/*.wasm`）
- 用環境變數指向共享位置

### Q: 執行時出現 "wasmtime binary not found"
**A:** 確認：
1. `wasmtime --version` 可執行
2. 或設定 `BLOCK2PYTHON_WASMTIME_BIN` 為完整路徑

### Q: 我想用原生 Python bindings 而非 CLI？
**A:** 可修改 `src/block2python/judge/wasm_runner.py`，加入 `wasmtime` Python 套件版本的 runner。目前 CLI 版本可跨語言且更穩定。

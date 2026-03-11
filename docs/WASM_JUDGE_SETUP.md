# Wasm Judge 完整環境設定與驗證指南

本文件說明如何配置與驗證 Block2Python 的 WebAssembly judge 隔離執行環境。

## 前置需求

### 1. 安裝 Wasmtime

**選項 A: 使用 winget (推薦)**
```powershell
winget install BytecodeAlliance.Wasmtime
```

**選項 B: 使用 Chocolatey**
```powershell
choco install wasmtime
```

**選項 C: 手動下載**
1. 前往 https://github.com/bytecodealliance/wasmtime/releases
2. 下載 `wasmtime-vXX.X.X-x86_64-windows.zip`
3. 解壓並加入 PATH

**選項 D: 使用 Python pip (wasmtime package)**
```powershell
pip install wasmtime
```

驗證安裝：
```powershell
wasmtime --version
```

### 2. 準備 python.wasm

專案已包含 `python.wasm` 檔案：
- 位置：`assets/wasm/python.wasm`
- 來源：https://github.com/vmware-labs/webassembly-language-runtimes/releases
- 版本：python/3.12.0+20231211-040d5a6

如需使用其他版本，請設定環境變數：
```powershell
$env:BLOCK2PYTHON_WASM_PATH = "path\to\your\python.wasm"
```

### 3. 安裝 Python 依賴

必須安裝 `psutil`（用於記憶體限制監控）和 `PyYAML`（用於 YAML 關卡載入）：
```powershell
pip install psutil PyYAML
```

或使用專案配置：
```powershell
pip install -e ".[dev]"
```

## 驗證步驟

### 快速驗證

執行完整驗證腳本：
```powershell
.\tools\verify_wasm_setup.ps1
```

此腳本會檢查：
1. wasmtime 是否可用
2. python.wasm 是否存在
3. Python 虛擬環境是否正常
4. WasmJudge AC 場景
5. WasmJudge WA 場景

### 測試邊界場景

測試 TLE (Time Limit Exceeded) 與 MLE (Memory Limit Exceeded)：
```powershell
.\tools\test_wasm_edge_cases.ps1
```

跳過 MLE 測試（如果 psutil 無法使用）：
```powershell
.\tools\test_wasm_edge_cases.ps1 -SkipMLE
```

### 手動測試

#### 測試基本 wasm 執行
```powershell
# 建議直接用專案驗證腳本（會自動涵蓋 Windows 相容策略）
.\tools\verify_wasm_setup.ps1
```

#### 測試 judge 整合
```powershell
$env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
$env:BLOCK2PYTHON_WASM_CODE_MODE = "auto"  # auto|inline|tempfile|stdin
python -m block2python
```

## 環境變數配置

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `BLOCK2PYTHON_JUDGE_MODE` | `auto` | Judge 模式：`auto`/`stub`/`wasm` |
| `BLOCK2PYTHON_WASM_PATH` | `assets/wasm/python.wasm` | python.wasm 檔案路徑 |
| `BLOCK2PYTHON_WASMTIME_BIN` | `wasmtime` | wasmtime 執行檔名稱或路徑 |
| `BLOCK2PYTHON_WASM_CODE_MODE` | `auto` | 傳碼策略：`auto`/`inline`/`tempfile`/`stdin` |
| `BLOCK2PYTHON_JUDGE_FAIL_FAST` | `true` | 是否在第一筆測資失敗時停止 |

`BLOCK2PYTHON_WASM_CODE_MODE` 說明：
- `auto`: 依序嘗試 `inline -> tempfile -> stdin`
- `inline`: 使用 `-c` 傳碼（最快，但 Windows 可能遇到 `//-c` 問題）
- `tempfile`: 寫入臨時檔並透過 WASI preopen 執行（Windows 推薦）
- `stdin`: 以 `python -` 從 stdin 讀取 wrapper 腳本，測資透過 WASI env 注入

## Judge 功能清單

### ✅ 已實作功能

- **輸入/輸出隔離**：透過 wasmtime WASI 沙箱執行
- **時間限制 (TLE)**：使用 `time_limit_ms` 配置，超時自動 kill 子程序
- **記憶體限制 (MLE)**：使用 `memory_limit_kb` 或 `memory_limit_mb` 配置，超標自動 kill
- **Verdict 類型**：AC / WA / TLE / MLE / RE / INTERNAL_ERROR
- **輸出正規化**：CRLF/LF、尾端空白、尾端換行
- **Fail-fast**：第一筆測資失敗即停止（可配置）
- **多測資格式**：支援 JSON/YAML + .in/.out 檔案

### 🎯 測資格式支援

#### 方式 1：直接嵌入關卡檔案
```yaml
testcases:
  - stdin: "1 2\n"
    expected_stdout: "3\n"
    name: sample-1
```

#### 方式 2：指定檔案路徑
```yaml
testcases:
  - name: case-01
    stdin_file: cases/add/01.in
    expected_stdout_file: cases/add/01.out
```

#### 方式 3：自動掃描目錄
```yaml
testcase_dir: cases/add-two-numbers
testcase_glob: "*.in"  # 可選，預設 *.in
```

## 範例關卡

專案已提供兩個 YAML 格式範例關卡：

### 1. add-two-numbers.yaml
- 使用 `testcase_dir` 自動掃描 `.in/.out` 檔案
- 配置：1000ms 時間限制，64MB 記憶體限制
- 測資：3 組（01.in/01.out, 02.in/02.out, 03.in/03.out）

### 2. fizzbuzz-simple.yaml
- 使用明確的 `stdin_file` / `expected_stdout_file` 指定測資
- 配置：1000ms 時間限制，32MB 記憶體限制
- 測資：4 組（明確列出）

啟動使用 YAML 關卡：
```powershell
$env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
python -m block2python
```

## 執行測試

### 執行所有 pytest 測試
```powershell
pytest -v
```

### 執行需要 wasm 的整合測試
```powershell
pytest -m requires_wasm -v
```

### Coverage 報告
```powershell
pytest --cov-report=html
Start-Process htmlcov/index.html
```

## 常見問題

### Q: wasmtime 找不到
**A:** 確認已加入 PATH 或設定 `BLOCK2PYTHON_WASMTIME_BIN` 為完整路徑。

### Q: MLE 檢測失敗
**A:** 確認已安裝 `psutil`：
```powershell
pip install psutil
```

### Q: 執行很慢
**A:** WASM 執行會比原生慢 2-5 倍，這是正常的隔離成本。調整 `time_limit_ms` 以符合實際需求。

### Q: YAML 關卡載入失敗
**A:** 確認已安裝 `PyYAML`：
```powershell
pip install PyYAML
```

### Q: 我需要更嚴格的隔離
**A:** 目前使用 WASI 沙箱，已限制檔案系統與網路存取。如需更強隔離，可考慮：
- Docker 容器
- 獨立的評測機
- 雲端 sandbox 服務

## 下一步

- [QUICKSTART.md](QUICKSTART.md) - 一般執行指南
- [docs/specs/levels_schema_v0_1.md](docs/specs/levels_schema_v0_1.md) - 關卡 schema 規格
- [tests/README.md](tests/README.md) - 測試執行說明

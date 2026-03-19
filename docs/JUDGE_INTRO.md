# Judge 介紹

本文件給開發者一個快速、完整的 Block2Python Judge 心智模型。

## 目標

Judge 服務負責在受控環境中執行玩家提交的 Python 程式，依照關卡測資輸出 verdict。

核心目標：

- 正確性：依測資判定 AC/WA
- 穩定性：可處理 RE/TLE/MLE/INTERNAL_ERROR
- 隔離性：以 Wasm/WASI 沙箱執行程式碼
- 可觀測性：提供 case 細節與耗時資訊

## 架構總覽

主要元件：

- `src/block2python/app/core.py`
  - 提交流程入口，串接 Analyzer + Judge
- `src/block2python/app/judge_factory.py`
  - 根據環境變數組裝 Judge 實例
- `src/block2python/judge/wasm_judge.py`
  - case-by-case 評測、彙整 verdict
- `src/block2python/judge/wasm_runner.py`
  - 透過 `wasmtime` 實際執行 `python.wasm`
- `src/block2python/judge/normalization.py`
  - 輸出正規化（換行/尾端空白/尾端換行）
- `src/block2python/judge/stub.py`
  - 開發/回退用的 stub judge

流程（簡化）：

1. AppCore 收到 `Submission`
2. JudgeFactory 產生 `StubJudge` 或 `WasmJudge`
3. WasmJudge 逐筆 testcase 呼叫 WasmtimeRunner
4. 依正規化策略比對 expected/actual
5. 產生 `JudgeResult` 與每筆 `CaseResult`

## Verdict 與 Case 狀態

`JudgeStatus`：

- `AC`
- `WA`
- `TLE`
- `MLE`
- `RE`
- `INTERNAL_ERROR`

`CaseResult.status`：

- `PASS`
- `FAIL`
- `TIMEOUT`
- `MEMORY_LIMIT`
- `ERROR`

## 模式與環境變數

常用配置：

- `BLOCK2PYTHON_JUDGE_MODE`
  - `auto | stub | wasm`
- `BLOCK2PYTHON_WASM_PATH`
  - `assets/wasm/python.wasm`（預設）
- `BLOCK2PYTHON_WASMTIME_BIN`
  - `wasmtime`（預設）
- `BLOCK2PYTHON_WASM_CODE_MODE`
  - `auto | inline | tempfile | stdin`
- `BLOCK2PYTHON_JUDGE_FAIL_FAST`
  - `true | false`

`BLOCK2PYTHON_WASM_CODE_MODE` 說明：

- `auto`: `inline -> tempfile -> stdin`
- `inline`: 直接 `-c` 傳碼
- `tempfile`: 寫入暫存檔後執行（Windows 推薦）
- `stdin`: `python -` + wrapper 執行

## 如何確認 Judge 可用

快速檢查：

```powershell
$env:PYTHONPATH = "src"
.\tools\verify_wasm_setup.ps1
```

邊界測試：

```powershell
$env:PYTHONPATH = "src"
.\tools\test_wasm_edge_cases.ps1 -SkipMLE -CodeMode auto
```

核心單元測試：

```powershell
$env:PYTHONPATH = "src"
.\.venv\Scripts\python.exe -m pytest -q tests\test_wasm_judge.py tests\test_judge_factory.py tests\test_levels_loader.py
```

## 常見問題

`No module named block2python`：

- 先設 `PYTHONPATH=src`
- 或透過 `tools/run_demo.ps1` / `tools/run_ui.ps1` 啟動

`wasmtime binary not found`：

- 確認 `wasmtime --version`
- 或設定 `BLOCK2PYTHON_WASMTIME_BIN`

`auto` 沒切到 wasm：

- 確認 `assets/wasm/python.wasm` 存在
- 確認 `BLOCK2PYTHON_JUDGE_MODE` 不是 `stub`

## 參考文件

- `docs/QUICKSTART.md`
- `docs/contributing/environment_setup.md`
- `docs/specs/levels_schema_v0_1.md`
- `tests/README.md`

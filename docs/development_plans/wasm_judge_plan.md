# Wasm Judge 完整實作計畫（2026）

## 1. 目標與範圍

本計畫目標是將目前 `StubJudge` 逐步替換為可用的 Wasm 原生評測流程，並保留既有 `Judge` 介面與 `contracts` 型別不變，確保 UI / AppCore 幾乎不需重寫。

本階段包含：
- 使用 WebAssembly (WASI) 執行 Python 程式碼
- 多測資逐筆評測與彙整
- 輸出正規化與比對
- timeout / runtime error / internal error 分流
- 最小 smoke test 與可觀測資訊（`elapsed_ms`、`stderr`、`exit_code`）

本階段不包含：
- 多語言評測（C/C++）
- 分散式評測佇列
- 雲端部署與遠端沙箱

## 2. 架構設計

### 2.1 分層

- Host（既有）: `AppCore -> Judge` 呼叫鏈
- Judge（新增）: `WasmJudge`，負責 testcase 迴圈、比較、結果彙整
- Runtime Adapter（新增）: `WasmRunner` Protocol + `WasmtimeRunner` 實作
- Contracts（既有）: `JudgeResult` / `CaseResult` / `JudgePolicy`

### 2.2 資料流

1. `AppCore.submit` 收到 `Submission`
2. `Analyzer` PASS 後呼叫 `WasmJudge.judge`
3. `WasmJudge` 逐筆 testcase 呼叫 `WasmRunner.execute`
4. `WasmJudge` 依 `JudgePolicy.output_normalization` 正規化並比對
5. 產生 `CaseResult[]` 與總結 `JudgeResult`
6. UI 顯示每筆失敗資訊與整體狀態

## 3. 核心規格

### 3.1 狀態對應

- 全部 testcase PASS -> `JudgeStatus.AC`
- 有 testcase FAIL -> `JudgeStatus.WA`
- 任一 testcase timeout -> `JudgeStatus.TLE`
- 任一 testcase runtime error（非 timeout）-> `JudgeStatus.RE`
- Host 端配置或 runtime 初始化失敗 -> `JudgeStatus.INTERNAL_ERROR`

### 3.2 輸出比對規則

依 `OutputNormalization` 控制：
- `normalize_newlines_to_lf`
- `strip_trailing_whitespace`
- `strip_trailing_newline`

比對以「正規化後字串全等」為準。

### 3.3 Timeout 規則

- 單筆 testcase 使用 `level.judge_policy.time_limit_ms`
- timeout 直接標記該筆 `TIMEOUT`
- 是否繼續跑後續測資（MVP 決策）:
  - 預設停止（fail-fast）以降低展示等待時間
  - 可在後續版本加 metadata 開關

## 4. 檔案與模組調整

### 4.1 新增

- `src/block2python/judge/normalization.py`
  - 輸出正規化工具
- `src/block2python/judge/wasm_runner.py`
  - `WasmRunner` Protocol + `ExecutionResult` + `WasmtimeRunner` 骨架
- `src/block2python/judge/wasm_judge.py`
  - `WasmJudge` 實作（testcase 迴圈、判定、彙整）

### 4.2 修改

- `src/block2python/judge/__init__.py`
  - 匯出 `WasmJudge` 等新物件
- `src/block2python/app/levels_loader.py`
  - 解析 `judge_policy`（`time_limit_ms` + `output_normalization`）

## 5. 里程碑

### M1: 可編譯骨架（本次）

- 建立 `WasmJudge` 與 `WasmRunner` 插拔介面
- 完成 output normalization 與 `JudgeResult` 組裝
- Loader 可載入 `judge_policy`

完成判準：
- 專案可 import 新模組
- 不影響既有 `StubJudge` 路徑

### M2: Wasmtime 真實執行

- 補齊 `WasmtimeRunner.execute`
- 正確注入 stdin / 擷取 stdout / stderr
- timeout 生效

完成判準：
- 能用實際 `python.wasm` 跑至少 1 題 2 筆測資

### M3: 稳定與驗證

- 補 smoke scripts（AC/WA/TLE/RE）
- 加入錯誤訊息分流與除錯欄位
- 確認 UI 呈現與使用者回饋可讀性

## 6. 風險與對策

- 風險: `python.wasm` 來源與 WASI 相容性不一致
- 對策: 在 `WasmtimeRunner` 加入啟動前驗證（版本/入口點檢查）

- 風險: Wasm Python 效能較原生慢
- 對策: 先以較寬鬆 time limit 驗證，再逐步調整

- 風險: API 版本差異（wasmtime Python bindings）
- 對策: 將與 wasmtime 的耦合集中於 `wasm_runner.py`

## 7. 開發任務拆解（可直接派工）

1. 實作 `normalize_output` 與單元範例
2. 實作 `WasmJudge.judge`（先用 fake runner 驗證流程）
3. `levels_loader` 讀入 `judge_policy`
4. `WasmtimeRunner` 加入真實執行
5. 建立 smoke 測試案例（AC/WA/TLE/RE）
6. 在 UI 顯示 `elapsed_ms`/`stderr`（必要時）

## 8. 驗收清單

- `judge_policy.time_limit_ms` 可影響 timeout
- 輸出正規化可配置
- `JudgeResult.case_results` 含實際 stdout/stderr/elapsed
- RE/TLE/WA/AC 狀態可穩定重現
- 未配置 wasm 環境時錯誤訊息可理解，不會讓 App 崩潰

## 9. 目前實作策略

- 預設仍維持 `StubJudge` 不變（避免中斷 Demo）
- 開發時透過依賴注入：`AppCore(..., judge=WasmJudge(...))`
- 等 M2 完成後再討論是否改為預設 `WasmJudge`

## 10. 實作狀態（2026-03-08）

- 已完成：`WasmJudge`、`WasmtimeRunner`（CLI 版本）、output normalization、`judge_policy` 載入
- 已完成：`BLOCK2PYTHON_JUDGE_MODE` 工廠切換（`auto|stub|wasm`）
- 已完成：`tests/smoke_wasm_judge.py`（AC/WA/TLE/RE/INTERNAL_ERROR）
- 已完成：UI 顯示 `judge_elapsed_ms` / `stderr` / case 細節
- 待完成：若要完全改為 Python wasmtime bindings（不依賴 CLI），可在 `wasm_runner.py` 再加 binding backend

為 WasmJudge 及相關組件新增全面測試

- 在 `tests/smoke_wasm_judge.py` 中引入 WasmJudge 執行的煙霧測試。
- 在 `tests/test_app_core.py` 中新增 AppCore 提交工作流程的單元測試。
- 在 `tests/test_judge_factory.py` 實現裁判工廠測試，以驗證基於環境的配置。
- 在 `tests/test_judge_normalization.py` 創建輸出正規化邏輯的測試。
- 在 `tests/test_levels_loader.py` 開發關卡加載器和裁判策略解析的測試。
- 在 `tests/test_smoke_wasm_full.py` 為 WasmJudge 執行使用真實場景新增完整的煙霧測試。
- 在 `tests/test_wasm_judge.py` 使用假執行器實現 WasmJudge 邏輯的單元測試。
- 新增 PowerShell 腳本，用於運行測試、驗證 Wasm 設定，以及測試與 TLE/MLE 相關的邊界情況。
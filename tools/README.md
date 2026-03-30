# Tools

這個目錄放的是專案用的 PowerShell 腳本。

## 先記這四支

- `tools/setup_dev_env.ps1`
  主環境建置入口。第一次把專案拉下來時，先跑這支。
- `tools/run_godot_client.ps1`
  啟動 Godot client。這是目前主要的前端入口。
- `tools/run_tests.ps1`
  手動跑 pytest。適合日常開發時快速驗證。
- `tools/run_project_gate.ps1`
  跑比較完整的 gate。適合收尾前一次檢查 coverage 與 judge。

## 環境建置

- `tools/setup_dev_env.ps1`
  主環境建置入口。建立 `.venv`，安裝開發依賴，並下載 Godot、Wasmtime、Blockly vendor 資源。
- `tools/setup_project.ps1`
  包裝腳本。先呼叫 `setup_dev_env.ps1`，再視需要執行 project gate。
  如果你只是想把環境建好，優先用 `setup_dev_env.ps1`。
- `tools/sync_blockly_vendor.ps1`
  只處理 Blockly vendor 同步。當你只想更新 Blockly，不想重跑整個 setup 時用這支。

## 日常開發

- `tools/run_godot_client.ps1`
  啟動 `godot_poc/`，這是目前主要的 client 入口。
- `tools/run_tests.ps1`
  執行 pytest，可附帶 pattern、marker、coverage。
- `tools/reset_progress.ps1`
  清除本機 progress 檔案 `.block2python/progress.json`。

## 題目產生（Level Authoring）

- `tools/level/`
  放每一題的題目生成腳本與 testlib 工作區（由 skill scaffold 產生）。
  建議一題一個資料夾：`tools/level/<problem_name>/`。
  對應的 Block2Python 關卡檔位於：
  - `assets/levels/<level_id>.yaml`
  - `assets/levels/cases/<level_id>/`

## 驗證與 Smoke Test

- `tools/smoke_bridge.ps1`
  用最小請求驗證 stdio bridge server 是否能正常回應。
- `tools/smoke_wasm.ps1`
  用 wasm judge 跑最小 CLI smoke flow。
- `tools/verify_wasm_env.ps1`
  驗證 wasmtime、`assets/wasm/python.wasm`、Wasm judge 的基本 AC/WA 流程。
- `tools/verify_wasm_limits.ps1`
  驗證 Wasm judge 的 TLE / MLE 類邊界情況。
- `tools/run_judge_precision_benchmark.ps1`
  跑 judge benchmark，觀察穩定性、耗時與記憶體表現。

## Legacy

舊的 CLI / PySide6 腳本已移到 `tools/legacy/`。
它們仍可作為開發或回歸檢查用途，但不是主線入口。

- `tools/legacy/run_cli_demo.ps1`
- `tools/legacy/run_pyside6_client.ps1`
- `tools/legacy/run_game_session_demo.ps1`

# Tools

本資料夾放開發用工具腳本。現在已依用途收斂成 3 類：主線入口、診斷/驗證、legacy 相容入口。

## 主線入口

- `tools/setup_dev_env.ps1`：建立 `.venv`、快速安裝開發依賴，並下載 Godot / Wasmtime；可選配 Blockly
- `tools/run_godot_poc.ps1`：從 repo 根目錄啟動 `godot_poc/project.godot`，預設優先使用 `.block2python/godot/4.6.1/` 內的 Godot
- `tools/reset_progress.ps1`：清除本機進度檔（`.block2python/progress.json`）
- `tools/run_tests.ps1`：pytest 入口，支援 pattern / marker / coverage
- `tools/vendor_blockly.ps1`：Blockly vendor 單一入口，可接受 URL、壓縮檔或已解壓目錄，並擺放靜態檔到 `assets/blockly/vendor/`

## 診斷與驗證

- `tools/run_bridge_smoke.ps1`：最小 stdio bridge smoke
- `tools/run_wasm_smoke.ps1`：以 wasm judge 跑最小 smoke
- `tools/verify_wasm_setup.ps1`：檢查 wasmtime / python.wasm / WasmJudge 基本 AC/WA
- `tools/test_wasm_edge_cases.ps1`：額外驗證 TLE / MLE

## Legacy

以下腳本保留給舊流程與歷史文件，不再是目前主線入口：

- `tools/legacy/run_demo.ps1`
- `tools/legacy/run_ui.ps1`
- `tools/legacy/run_game_session_demo.ps1`

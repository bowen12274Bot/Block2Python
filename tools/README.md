# Tools（待補）

本資料夾預留放開發用工具腳本（例如：關卡資料檢查、輸出比對、文件產生等）。

- `tools/setup_dev_env.ps1`：建立 `.venv` 並安裝開發依賴（目前含 `PySide6`）
- `tools/run_demo.ps1`：用 `PYTHONPATH=src` 啟動目前的 demo placeholder
- `tools/run_ui.ps1`：啟動 PySide6 UI（需先安裝 `PySide6`）
- `tools/reset_progress.ps1`：清除本機進度檔（`.block2python/progress.json`）
- `tools/vendor_blockly.ps1`：下載並擺放 Blockly 靜態檔到 `assets/blockly/vendor/`（需自行提供 `BLOCKLY_DIST_URL`）
- `tools/vendor_blockly_from_dir.ps1`：從已解壓的 dist 目錄擺放 Blockly 靜態檔到 `assets/blockly/vendor/`（使用 `BLOCKLY_DIST_DIR`）
- `tools/run_judge_precision_benchmark.ps1`：重複壓測 Wasm Judge 的 AC 精度、耗時分佈、記憶體成長與 TLE/MLE 防護

## 一鍵設定

建議用以下指令完成環境初始化（建立 `.venv`、安裝 `requirements.txt`、安裝 editable package、跑 project gate）：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\setup_project.ps1
```

常用參數：

```powershell
# 重新建立虛擬環境
powershell -ExecutionPolicy Bypass -File .\tools\setup_project.ps1 -RecreateVenv

# 只做安裝，不跑 gate
powershell -ExecutionPolicy Bypass -File .\tools\setup_project.ps1 -SkipGate

# gate 時要求 Blockly vendor 必須存在
powershell -ExecutionPolicy Bypass -File .\tools\setup_project.ps1 -RequireBlocklyVendor
```

相容性：

- `tools/setup_dev_env.ps1` 仍可使用，但目前只是轉呼叫 `tools/setup_project.ps1`。

## Judge 精度壓測

建立期可用以下指令快速確認「多次判題是否穩定 AC、是否異常變慢、是否可能記憶體飆升」：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_judge_precision_benchmark.ps1 -Runs 30 -WarnElapsedMs 1800 -CodeMode auto
```

補充：

- 壓測題目使用 `assets/levels/judge-precision-sum-series.yaml`。
- 會另外執行 sandbox guard：TLE 應觸發 `TLE`；記憶體壓力測試應觸發 `MLE` 或 `RE`。
- 若希望檢查不通過時回傳非 0，可加 `-Strict`。

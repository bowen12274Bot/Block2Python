# Tools（待補）

本資料夾預留放開發用工具腳本（例如：關卡資料檢查、輸出比對、文件產生等）。

- `tools/setup_dev_env.ps1`：建立 `.venv` 並安裝開發依賴（目前含 `PySide6`）
- `tools/run_demo.ps1`：用 `PYTHONPATH=src` 啟動目前的 demo placeholder
- `tools/run_ui.ps1`：啟動 PySide6 UI（需先安裝 `PySide6`）
- `tools/reset_progress.ps1`：清除本機進度檔（`.block2python/progress.json`）
- `tools/vendor_blockly.ps1`：下載並擺放 Blockly 靜態檔到 `assets/blockly/vendor/`（需自行提供 `BLOCKLY_DIST_URL`）
- `tools/vendor_blockly_from_dir.ps1`：從已解壓的 dist 目錄擺放 Blockly 靜態檔到 `assets/blockly/vendor/`（使用 `BLOCKLY_DIST_DIR`）

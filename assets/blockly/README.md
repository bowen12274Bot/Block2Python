# Blockly（靜態檔 / Vendor）

本資料夾用於放置 **Blockly 的靜態檔**，並由 `QWebEngineView` 載入（Demo 期先做單機、無外部瀏覽器）。

目前 `assets/blockly/index.html` 支援兩種模式：

1. **Blockly 已 vendored（推薦）**：會載入 `assets/blockly/vendor/` 下的 Blockly 檔案並顯示 Workspace。
2. **尚未 vendored**：會退回 placeholder 模式（仍可用 Web↔Desktop 橋接測試）。

## Vendor 檔案位置

請把 Blockly 的 dist 檔案放到：

- `assets/blockly/vendor/`

至少需要（檔名以官方 dist 為準）：

- `blockly_compressed.js`
- `blocks_compressed.js`
- `python_compressed.js`
- `msg/zh-hant.js`（或你選擇的語系）

> 若你想改語系，請同步調整 `assets/blockly/index.html` 的 script 引用。

## 版本控制策略（目前）

目前 `assets/blockly/vendor/` 設為不進版控（避免 repo 變大）。

- 下載/解壓得到的來源資料可放在 `.block2python/`（不進版控）
- 之後用工具腳本把必要檔案拷貝到 `assets/blockly/vendor/` 供 UI 載入

## 取得方式（建議）

使用工具腳本下載/擺放（需要網路）：

- `tools/vendor_blockly.ps1`

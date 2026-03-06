# 專案架構（Project Structure）

- 更新日期：2026-03-06
- 文件定位：本文件用於說明 Block2Python（Demo）專案的資料夾結構，以及各文件之間的依賴/引用關係，方便團隊協作與交接。

## 1. 專案根目錄（Top-level）

```
Block2Python/
  src/            # 主要 Python 程式碼（package）
  assets/         # 靜態資源（關卡資料、Blockly web 檔等）
  tools/          # 開發輔助腳本（setup、run、vendor）
  tests/          # 測試（目前以 smoke/預留為主）
  docs/           # 文件（需求、技術策略、計畫、規格、UML）
  .block2python/  # 本機狀態/暫存（不進版控）
  .venv/          # 開發用虛擬環境（不進版控）
```

### 1.1 不進版控資料夾

- `.venv/`：每位開發者本機的 Python 虛擬環境（見 `docs/contributing.md`）
- `.block2python/`：本機進度檔、下載/解壓暫存等（見 `docs/contributing.md`）

## 2. 文件資料夾（docs/）

```
docs/
  README.md
  requirements.md
  technical_rationale.md
  project_plan.md
  development_timeline.md
  contributing.md
  development_plans/
  specs/
  uml/
```

### 2.1 文件角色與關係（建議閱讀順序）

1) **需求（What）**：`docs/requirements.md`  
定義 MVP scope、學習流程、功能需求與非功能需求。

2) **技術策略（Why）**：`docs/technical_rationale.md`  
說明分層架構與技術選型理由（不等同實作規格）。

3) **規格（Exact）**：`docs/specs/`  
把跨層資料格式、schema、API 等細節獨立收斂（避免混進技術策略文件）。

4) **UML（視覺化對齊）**：`docs/uml/system_architecture.md`  
用元件圖對齊分層與資料流（對應技術策略文件的分層章節）。

### 2.2 docs/ 子資料夾

- `docs/development_plans/`：更細的開發/引入計畫與驗證  
  - `technical_introduction_plan.md`：建立期技術引入計畫  
  - `technical_introduction_plan_verification.md`：建立期完成驗證與狀態說明

- `docs/specs/`：可被實作依賴的「格式/規格」文件  
  - `levels_schema_v0_1.md`：關卡檔 schema（v0.1，建立期寬鬆版）  
  - `block_json_schema_v0_1.md`：Block JSON schema（v0.1，建立期）

- `docs/uml/`：架構圖與圖檔  
  - `system_architecture.md`：Mermaid 元件圖  
  - `system_architecture.png`：輸出圖片版

## 3. 程式碼（src/）

主要 package：`src/block2python/`

對應分層（與 `docs/technical_rationale.md`、`docs/uml/system_architecture.md` 一致）：

- `src/block2python/app/`：應用整合層（關卡流程、解鎖、提交管線）
- `src/block2python/ui/`：桌面 UI（PySide6 Widgets + WebEngine）
- `src/block2python/contracts/`：資料契約（跨層資料結構）
- `src/block2python/analysis/`：AST 分析（建立期最小規則 + 可擴充）
- `src/block2python/judge/`：判題介面與 stub（真實 sandbox/judge 後續替換）
- `src/block2python/blockly/`：預留（未來可放 Blockly adapter/抽象）
- `src/block2python/ai/`：預留（Phase 5）

## 4. 資料與靜態資源（assets/）

- `assets/levels/`：關卡資料（由程式載入）
  - `index.json`：關卡索引
  - `*.json`：單關卡內容（對應 `docs/specs/levels_schema_v0_1.md`）
- `assets/blockly/`：WebEngine 載入的 web 資源
  - `index.html`：建立期 placeholder + workspace（vendor 後可用）
  - `vendor/`：Blockly dist 檔（目前不進版控；由工具腳本擺放）

## 4.1 執行期資料與狀態（Runtime State）

以下資料屬於系統執行期狀態，不建議放在 `requirements.md`，而應在架構/資料設計文件中管理：

- 關卡解鎖狀態
- 章節／任務進度
- 已讀對話或劇情節點狀態
- 關卡路線的選擇結果或節點進度

目前本機狀態主要存放在 `.block2python/`（見 `docs/contributing.md`），後續若資料結構擴充，應再獨立補充 schema 或狀態格式文件。

## 5. 工具腳本（tools/）

- `tools/setup_dev_env.ps1`：建立 `.venv` 並安裝依賴
- `tools/run_demo.ps1`：跑 CLI smoke
- `tools/run_ui.ps1`：啟動 UI smoke
- `tools/reset_progress.ps1`：清除本機進度
- `tools/vendor_blockly.ps1` / `tools/vendor_blockly_from_dir.ps1`：擺放 Blockly dist 到 `assets/blockly/vendor/`

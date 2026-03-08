# 專案架構（Project Architecture）

- 最後更新：2026-03-08
- 本文件說明 Block2Python 專案目前的目錄結構、主要模組分工、靜態資源配置、工具腳本，以及 agent skills 的使用方式。

## 1. 專案根目錄

```text
Block2Python/
  .agent/         # 唯一的 canonical agent skills source
  .agents/        # 其餘模型入口
  .block2python/  # 專案本機執行期狀態，不進版控
  .claude/        # Claude Code 模型入口
  .codex/         # Codex 模型入口
  .venv/          # 開發用 Python 虛擬環境，不進版控
  assets/         # 靜態資源，例如關卡資料與 Blockly vendor 檔案
  docs/           # 架構、規格、開發計畫與協作文件
  src/            # 核心 Python 程式碼
  tests/          # 測試與 smoke test
  tools/          # 開發與維運腳本
  .gitignore      # Git 忽略規則
  README.md       # 專案入口說明
  skills-lock.json  # skills 鎖定資訊
```

### 1.1 不進版控資料夾

- `.venv/`：本機 Python 開發環境，建立與使用方式見 `docs/contributing.md`。
- `.block2python/`：本機執行期狀態、快取與暫存資料，細節見 `docs/contributing.md`。

### 1.2 Agent Skills 入口

- `.agent/`：skills 的唯一來源，真正的 `SKILL.md` 與 bundled resources 都放在這裡。
- `.agents/`、`.claude/`、`.codex/`：不同 AI 模型的入口層，用來讓各模型接上 `.agent` 這份 canonical skills；它們不是獨立的 skill source。
- `skills-lock.json`：記錄已安裝或已鎖定的 skill 來源與 hash。

## 2. 文件資料夾（docs/）

```text
docs/
  README.md
  requirements.md
  technical_rationale.md
  project_plan.md
  development_timeline.md
  contributing.md
  project_architecture.md
  development_plans/
  specs/
  uml/
```

### 2.1 文件分工

- `requirements.md`：定義需求、目標與 MVP 範圍。
- `technical_rationale.md`：說明技術選型與架構考量。
- `project_plan.md`、`development_timeline.md`：記錄整體開發規劃與時程。
- `contributing.md`：整理開發環境、Git 流程、Blockly vendor、smoke test 等協作規範。
- `development_plans/`：各主題的實作計畫、驗證與 review 文件。
- `specs/`：資料格式與 JSON schema。
- `uml/`：系統架構圖與相關視覺化文件。

## 3. 程式碼（src/）

核心 package 位於 `src/block2python/`，目前主要分成下列模組：

- `app/`：應用程式啟動與組裝流程。
- `ui/`：PySide6 視窗、Widget 與 UI 整合。
- `blockly/`：Blockly 與 WebEngine 之間的橋接層。
- `analysis/`：分析或 AST 相關能力。
- `judge/`：評測或執行結果檢查相關能力。
- `contracts/`：模組間共用的介面與資料契約。
- `ai/`：與 AI 能力相關的擴充模組。

## 4. 資料與靜態資源（assets/）

```text
assets/
  README.md
  blockly/
    README.md
    index.html
    vendor/
  levels/
    index.json
    demo-1.json
    demo-2.json
```

### 4.1 `assets/levels/`

- 儲存關卡索引與範例關卡資料。
- `index.json` 作為關卡入口。
- `demo-1.json`、`demo-2.json` 提供目前的示範內容。

### 4.2 `assets/blockly/`

- `index.html` 提供 Blockly Web 端載入入口。
- `vendor/` 放置 vendored Blockly dist，供 UI 端直接載入。

### 4.3 執行期資料與狀態

- `.block2python/` 用來保存本機執行期資料，不納入版控。
- 這類資料應與 `assets/` 的靜態內容分離，避免將本機狀態混入正式資源。

## 5. 工具腳本（tools/）

- `setup_dev_env.ps1`：建立 `.venv` 與安裝開發依賴。
- `run_demo.ps1`：執行 CLI demo 或 smoke flow。
- `run_ui.ps1`：啟動 UI smoke flow。
- `reset_progress.ps1`：重置本機進度與狀態資料。
- `vendor_blockly.ps1`：從下載來源匯入 Blockly dist。
- `vendor_blockly_from_dir.ps1`：從本機目錄匯入 Blockly dist。

## 6. Agent Skills

本專案採用單一來源的 skills 架構，讓多個 AI 模型都共用同一份 canonical skill 定義。

```text
Block2Python/
  .agent/
    skills/                 # 唯一 canonical skills source
    README.md               # 維護原則與各個skills的說明
  .agents/                  # 其餘模型入口
  .claude/                  # Claude Code 模型入口
  .codex/                   # Codex 模型入口
  skills-lock.json          # skills 鎖定資訊
```

### 6.1 分層原則

- `.agent/skills/` 存放真正的 skill 定義與 bundled resources。
- `.agents/`、`.claude/`、`.codex/` 只負責讓不同 AI 模型接上同一套 canonical skills，不應作為獨立 skill source。
- `skills-lock.json` 是 skill 的 lock layer，用來記錄已安裝或已鎖定 skill 的來源與 hash 中繼資料。

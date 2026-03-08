# 貢獻指南

- 文件版本：1.0.0
- 更新日期：2026-03-08

本文件是 Block2Python 的人類協作入口。目標是讓新加入的開發者能快速把專案跑起來，理解最小必要的開發流程，並知道更深入的規則應該去哪裡查。

## 1. 快速開始

### 1.1 取得原始碼

```powershell
git clone <REPO_URL>
cd Block2Python
```

### 1.2 建立開發環境

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
```

### 1.3 下載並 vendor Blockly dist

UI 需要 Blockly dist 靜態檔才能正常運作。

```powershell
$env:BLOCKLY_DIST_URL = "https://github.com/RaspberryPiFoundation/blockly/releases/download/blockly-v12.4.1/blockly-12.4.1.tgz"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

### 1.4 跑 smoke test

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

更完整的環境與 Blockly 說明請見 `docs/contributing/environment_setup.md`。

## 2. 基本開發流程

建議流程：

```text
從 main 建立分支 -> 在分支上修改 -> 自行驗證 -> 整理 commit -> 開 PR -> 合併回 main
```

最小原則：

- 正式變更不要直接提交到 `main`
- `docs/` 與 `.agent/skills/` 的修改也應走分支與 PR
- 每個 PR 盡量聚焦單一主題
- 合併前至少提供一次可重現的驗證結果

更完整的 Git、PR、squash 與驗證規則請見 `docs/contributing/developer_workflow.md`。

## 3. 任務與排程

本專案目前以 Notion 作為手動排程工具。

- 任務即時狀態以 Notion 為準
- 實際完成的變更以 GitHub commit / PR 為準
- 若任務較大，建議搭配 `docs/development_plans/README.md` 與相關計畫文件保存規劃內容

## 4. 其他文件怎麼看

- `docs/contributing/environment_setup.md`
  - 本機環境、依賴管理、Blockly vendor、`.block2python/`
- `docs/contributing/developer_workflow.md`
  - 分支、commit、PR、squash、驗證、DoD
- `docs/contributing/code_guidelines.md`
  - 代碼一致性與基本寫法
- `docs/contributing/ai_collaboration.md`
  - AI agent 的閱讀順序、規劃入口與回報原則
- `docs/development_plans/README.md`
  - 開發計畫文件的用途與管理方式
- `docs/project_architecture.md`
  - 專案分層、模組責任與功能落點

## 5. AI 相關說明

本文件以人類快速開始為主。AI agent 的閱讀順序、規劃流程與回報原則，請改看 `docs/contributing/ai_collaboration.md` 與 `.agent/skills/`。

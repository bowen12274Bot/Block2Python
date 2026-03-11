# 貢獻指南

- 文件版本：1.1.1
- 更新日期：2026-03-11

本文件是 Block2Python 的人類協作入口。目標是讓新加入的開發者知道應該先看哪些文件、如何參與開發，以及協作變更的最小原則。

## 1. 加入專案

### 1.1 取得原始碼

```powershell
git clone <REPO_URL>
cd Block2Python
```

### 1.2 先讀哪些文件

建議閱讀順序：

- `docs/QUICKSTART.md`
  - 最短啟動路徑、CLI / GUI 啟動、judge 模式、基本驗證
- `docs/contributing/environment_setup.md`
  - `.venv`、Blockly vendor、Wasm judge、驗證腳本、本機資料
- `docs/project_architecture.md`
  - 模組分層與責任邊界
- `docs/contributing/developer_workflow.md`
  - 分支、commit、PR、pytest 驗證與合併規則

如果你的目標只是把專案跑起來，先看 `docs/QUICKSTART.md` 即可。

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
- 驗證以 `pytest` 為主，smoke script 為輔

更完整的 Git、PR、squash 與驗證規則請見 `docs/contributing/developer_workflow.md`。

## 3. 任務與排程

本專案目前以 Notion 作為手動排程工具。

- 任務即時狀態以 Notion 為準
- 實際完成的變更以 GitHub commit / PR 為準
- 若任務較大，建議搭配 `docs/development_plans/README.md` 與相關計畫文件保存規劃內容

## 4. 文件分工

- `docs/QUICKSTART.md`
  - 快速上手與執行指令
- `docs/contributing/environment_setup.md`
  - 本機環境、依賴管理、Blockly vendor、`.block2python/`
- `docs/contributing/developer_workflow.md`
  - 分支、commit、PR、pytest 驗證、DoD
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

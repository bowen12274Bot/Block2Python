---
name: contributing
description: 說明如何參與 Block2Python 專案。用於加入專案、快速上手、開發環境設定、vendor Blockly、理解 Git workflow、撰寫 commit message、開 PR、加入新依賴、遵守程式風格或執行驗證流程時。
---

# Contributing to Block2Python

使用此 skill 處理 Block2Python 的協作、貢獻與開發流程問題。

協作指南入口：[`docs/contributing.md`](../../../docs/contributing.md)

當問題涉及以下主題時，應依需要讀對應子文件，而不是每次都讀完整協作文件。

## 快速對照

| 主題 | 對應文件 |
|---|---|
| 快速開始與啟動指令 | `docs/QUICKSTART.md` |
| 協作入口與文件導覽 | `docs/contributing.md` |
| 開發環境設定與 Blockly vendor | `docs/contributing/environment_setup.md` |
| Git workflow、PR、驗證 | `docs/contributing/developer_workflow.md` |
| 開發規範 | `docs/contributing/code_guidelines.md` |
| AI 協作與 planning 入口 | `docs/contributing/ai_collaboration.md` |
| 開發計畫文件 | `docs/development_plans/README.md` |

## 核心入口（Windows PowerShell）

```powershell
# 最短上手
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1

# UI 驗證
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

更完整的命令與說明：

- `docs/QUICKSTART.md`
- `docs/contributing/environment_setup.md`
- `docs/contributing/developer_workflow.md`

目前驗證原則：

- `pytest` 是主要測試入口
- `tools/run_demo.ps1`、`tools/run_ui.ps1`、`tools/run_wasm_smoke.ps1` 是輔助 smoke 驗證

## 使用原則

- 問題如果屬於「怎麼加入專案、怎麼操作流程、怎麼遵守規範」，使用此 skill。
- 問題如果屬於「先把專案跑起來」，優先讀 `docs/QUICKSTART.md`。
- 問題如果屬於「環境、依賴、Wasm、Blockly vendor」，讀 `docs/contributing/environment_setup.md`。
<<<<<<< HEAD
- 問題如果屬於「正式 commit / PR / 驗證規則」，讀 `docs/contributing/developer_workflow.md`。
=======
>>>>>>> merge/judge_introduction_branch
- 問題如果屬於「系統怎麼分層、功能該放哪裡」，改用 `project-architecture`。
- 問題如果屬於「實際要怎麼改程式」，改用 `feature-implementation`。
- 如果是開始實作前要判斷是否需要計畫文件，改用 `development-planning`。

## 注意事項

- Python 開發環境以 repo 內的 `.venv` 為主。
- `assets/blockly/vendor/` 是 Blockly dist 的目標位置，不應手動隨意變更來源。
- `.block2python/` 屬於本機執行期狀態，不應納入版控。
- 若 setup 或執行流程失敗，優先回頭檢查 `tools/` 內的既有腳本與 `docs/contributing/environment_setup.md`。

---
name: feature-implementation
description: 用於 Block2Python 的功能實作、重構與維護工作。當需求涉及新功能開發、bug 修正、程式碼變更、與架構一致的重構，或任何本 repository 內的實作任務時使用。
---

# Feature Implementation

使用此 skill 處理 Block2Python 的程式碼實作與變更工作。

## 範圍

- 在 `src/block2python/` 中實作新功能
- 修正應用程式、UI、Blockly 整合或工具腳本中的問題
- 在維持專案架構一致的前提下進行重構
- 當行為變更影響既有流程時，補上或更新測試與 smoke test 驗證

## 開發前必讀

在開始實作前，先建立最小必要上下文：

- 架構總覽：[`docs/project_architecture.md`](../../../docs/project_architecture.md)
- 協作入口：[`docs/contributing.md`](../../../docs/contributing.md)
- AI 協作規範：[`docs/contributing/ai_collaboration.md`](../../../docs/contributing/ai_collaboration.md)
- 開發流程與驗證：[`docs/contributing/developer_workflow.md`](../../../docs/contributing/developer_workflow.md)
- 代碼規範：[`docs/contributing/code_guidelines.md`](../../../docs/contributing/code_guidelines.md)
- 既有開發計畫：`docs/development_plans/`

如果任務已經有對應的開發計畫，先讀計畫再開始動手。

如果任務還沒有開發文件，不要直接假設一定要先寫完整計畫。此時應改用 `development-planning` skill，判斷應該：

- 直接實作
- 先在 AI 對話中整理簡短計畫
- 先產出完整開發計畫文件

## 工作原則

- 所有變更都應與 `docs/project_architecture.md` 的分層原則一致。
- 優先做聚焦且可驗證的修改，避免無必要的大範圍重寫。
- 如果需求牽涉功能落點或模組邊界，先用 `project-architecture` 建立架構判準，再進入實作。
- 如果程式變更影響既有工作流程、文件或使用方式，應同步更新附近最相關的文件。
- 實作時應優先確認最小可交付結果，再補上必要的驗證與收尾。

## AI 開發工作流

1. 先確認需求屬於新功能、修 bug、重構，還是維護性修改。
2. 讀架構總覽、協作規範，以及已有的開發計畫。
3. 若沒有開發計畫，改用 `development-planning` 判斷這次任務需要的計畫強度。
4. 若涉及架構判斷，先參考 `project-architecture`，不要直接憑感覺決定落點。
5. 以最小修改集完成目標，避免把多個不相干問題綁在同一個變更裡。
6. 針對實際改動範圍執行最窄但足夠的驗證。
7. 回報結果時要清楚說明做了什麼、為什麼這樣做、以及有哪些尚未驗證的風險。

## 驗證

若變更影響 CLI 或 UI 流程，使用既有 smoke scripts：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

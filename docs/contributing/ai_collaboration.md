# AI 協作規範

- 文件版本：0.1.0
- 更新日期：2026-03-08

本文件提供 AI agent 與維護者使用，說明 AI 在 Block2Python repo 中應優先閱讀哪些文件、何時需要開發計畫，以及回報結果時應保留哪些資訊。

## 1. 文件閱讀順序

AI 在開始分析或修改前，應先建立最小必要上下文：

1. `docs/project_architecture.md`
2. `docs/contributing.md`
3. 與任務直接相關的子文件：
   - 環境與本機資料：`docs/contributing/environment_setup.md`
   - Git / PR / 驗證：`docs/contributing/developer_workflow.md`
   - 代碼一致性：`docs/contributing/code_guidelines.md`
4. 既有開發計畫：`docs/development_plans/`
5. 相關 skill 文件：`.agent/skills/`

原則：

- 不要每次都全文讀完所有文件，只讀這次任務真正需要的部分
- 若任務已經有對應計畫，先讀計畫再實作
- 若文件與實作不一致，優先指出差異，再做判斷

## 2. 何時需要開發計畫

是否需要完整計畫，應由 `development-planning` skill 判斷。

適用原則：

- 小而明確的修改，可直接實作
- 中等複雜任務，可先在對話中整理短計畫
- 大型、跨模組、涉及架構或流程設計的任務，才建立正式開發計畫文件

開發計畫文件的用途與管理方式，請見 `docs/development_plans/README.md`。

## 3. AI 與人類文件的責任分界

- `docs/contributing.md`：人類快速開始入口
- `docs/contributing/environment_setup.md`：本機環境與 Blockly vendor 細節
- `docs/contributing/developer_workflow.md`：Git、PR、驗證與 DoD
- `docs/contributing/code_guidelines.md`：代碼一致性
- `docs/development_plans/README.md`：開發計畫文件的管理方式
- `.agent/skills/`：AI 的操作流程與工作判準

原則：

- 不把所有 AI 規則堆回 `docs/contributing.md`
- 不在多份文件重複維護同一套 planning 規則
- skill 若需要引用文件，應盡量指向最精準的那一份

## 4. AI 實作工作流

1. 確認任務類型：新功能、修 bug、重構、文件調整或流程維護
2. 讀架構與最相關的協作文檔
3. 若缺乏計畫，使用 `development-planning` 判斷計畫強度
4. 若涉及功能落點或模組邊界，先使用 `project-architecture`
5. 以最小修改集完成目標
6. 執行與改動範圍相符的最小充分驗證
7. 回報結果、理由、驗證與剩餘風險

## 5. 回報原則

AI 回報時應清楚說明：

- 做了什麼
- 為什麼這樣做
- 跑了哪些驗證，或為什麼沒有跑
- 是否有尚未驗證的風險
- 若修改文件結構或協作規範，是否同步更新相關 skill 或引用點

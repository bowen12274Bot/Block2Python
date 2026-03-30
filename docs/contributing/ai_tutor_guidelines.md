# AI Tutor 內容編寫與維護指南

- 文件版本：0.1
- 更新日期：2026-03-30
- 適用對象：教學設計、內容維護者、AI 功能開發者

## 1. 目的

本文件定義 teaching skill 內容的編寫原則、審核重點與提交流程，目標是讓 tutor 回覆保持：

- 可預期
- 可教學
- 不越界

## 2. 核心原則

- 提示優先：避免直接完整解答
- 漸進引導：由寬到窄（hint ladder）
- 範圍控制：只在本關卡概念內引導
- 文案一致：語氣、步驟數、回覆長度可控

## 3. 新增 skill 的標準流程

1. 在 `assets/teaching_skills/` 新增 `<skill_id>.json`
2. 依 `docs/specs/teaching_skill_schema.md` 填寫欄位
3. 在目標 level YAML 加入 `teaching_skill_ids`
4. 必要時設定 `tutor_policy`
5. 執行測試
6. 送 PR 並附內容審核說明

## 4. 欄位撰寫建議

### 4.1 `learning_goals`

- 建議 2-5 項
- 每項聚焦一個可觀察學習目標
- 避免過大敘述（例如「學會 Python」）

### 4.2 `allowed_concepts` / `forbidden_concepts`

- `allowed_concepts`：本關允許提及的概念關鍵字
- `forbidden_concepts`：本關明確禁止引導的概念
- 兩者共同決定 policy 的拒答邊界

### 4.3 `hint_ladder`

建議至少 3 層：

1. 高層方向（不給實作細節）
2. 具體步驟（拆解任務）
3. 幾乎可操作的提示（但不給完整答案）

### 4.4 `common_mistakes`

每個 mistake 最好可回答三件事：

- 學生錯在哪（`pattern`）
- 為什麼錯（`diagnosis`）
- 下一步怎麼修（`hint`）

### 4.5 `refusal_rules`

建議至少包含：

- 不給完整解答
- 不引入超綱概念
- 引導學生從題目輸入輸出出發

## 5. 文案風格

- 短句優先，單輪只給一到兩個關鍵行動
- 避免抽象空話（例如「再想想看」）
- 優先使用「下一步可做什麼」的表達
- 語氣需符合 `answer_style.tone`

## 6. 審核清單（Review Checklist）

提交前確認：

- JSON 結構符合 schema
- `hint_ladder` 非空且具漸進性
- `allowed_concepts` / `forbidden_concepts` 無衝突
- `common_mistakes` 有可行修正建議
- level YAML 的 `teaching_skill_ids` 已連接
- 必要測試已通過

## 7. 驗證命令

```powershell
c:/Users/tange/Desktop/all_project/比賽/Block2Python/.venv/Scripts/python.exe -m pytest tests/ai/test_teaching_skill_loader.py tests/test_levels_loader.py tests/test_bridge_stdio.py
```

## 8. 常見錯誤

- `skill_id` 與檔名不一致
- `hint_ladder` 留空或只有一句泛用文案
- `conversation` 類需求寫入 skill（應放在 tutor request/session 層）
- 在 beginner 關卡引導到進階語法

## 9. 相關文件

- `docs/specs/teaching_skill_schema.md`
- `docs/development_plans/ai_tutor_api_contract.md`
- `src/block2python/ai/README.md`
- `docs/development_plans/ai_integration_implementation_plan.md`

# Teaching Skill Schema 規格（v0.1）

- 文件版本：0.1
- 更新日期：2026-03-30
- 適用範圍：`assets/teaching_skills/*.json`
- Source of truth：`src/block2python/ai/teaching_skill_loader.py`

## 1. 目的

本文件定義 teaching skill JSON 的資料格式與目前 loader 驗證行為，供教學內容編寫與程式整合使用。

## 2. 檔案結構

目前採單層結構：

- `assets/teaching_skills/README.md`
- `assets/teaching_skills/<skill_id>.json`
- `assets/teaching_skills/index.json`（可選；目前 loader 會略過）

## 3. 根物件（Root Object）

每份 skill 檔必須是 JSON object。

### 3.1 必填欄位

- `skill_id: string`（非空）
- `title: string`（非空）
- `hint_ladder: array[string]`（至少 1 個元素）

### 3.2 可選欄位

- `version: string | null`
- `description: string`
- `applies_to: object`
- `student_level: "beginner" | "intermediate" | "advanced"`
- `learning_goals: array[string]`
- `allowed_concepts: array[string]`
- `forbidden_concepts: array[string]`
- `common_mistakes: array<object>`
- `refusal_rules: array[string]`
- `answer_style: object`
- `metadata: object`

## 4. 欄位詳細規格

### 4.1 `applies_to`

```json
{
  "level_ids": ["group-01-demo"],
  "concepts": ["input", "output"]
}
```

- `level_ids`: array[string]，預設 `[]`
- `concepts`: array[string]，預設 `[]`

### 4.2 `student_level`

允許值：

- `beginner`
- `intermediate`
- `advanced`

未提供時預設 `beginner`。

### 4.3 `common_mistakes`

每個元素需為 object，且包含：

- `pattern: string`（非空）
- `diagnosis: string`（非空）
- `hint: string`（非空）

### 4.4 `answer_style`

```json
{
  "tone": "clear",
  "max_steps": 3,
  "max_response_length": 500
}
```

- `tone`: `clear | friendly | formal`，預設 `clear`
- `max_steps`: 正整數，預設 `3`
- `max_response_length`: 正整數，預設 `500`

## 5. Loader 驗證與正規化行為

### 5.1 字串與陣列

- 字串會做 `strip()`
- 陣列元素必須是非空字串，否則視為格式錯誤
- 非法型別（例如把陣列寫成 object）會觸發 `TeachingSkillValidationError`

### 5.2 `load_skill(skill_id)` 額外檢查

- 讀取路徑：`<skills_dir>/<skill_id>.json`
- 檔內 `skill_id` 必須與函式傳入值相同
- 不一致會拋出 `TeachingSkillValidationError`

### 5.3 `load_skills_for_level` / `find_skills_by_concept`

- 會掃描 `*.json`
- 會略過 `index.json`
- 無效 JSON 或不合法 schema 檔案會被跳過並記錄 warning（不中斷整體流程）

### 5.4 `metadata`

- `metadata` 若為 object，會保留
- 非 object 時會被視為空 object

## 6. 最小合法範例

```json
{
  "skill_id": "input-output-basics",
  "title": "Input / Output Basics",
  "hint_ladder": [
    "先確認輸入輸出格式。"
  ]
}
```

## 7. 完整範例

```json
{
  "skill_id": "variables",
  "version": "1.0",
  "title": "變數基礎",
  "description": "引導學生使用變數儲存中間結果",
  "applies_to": {
    "level_ids": ["group-01-practice-01"],
    "concepts": ["variables"]
  },
  "student_level": "beginner",
  "learning_goals": ["理解指派", "命名變數"],
  "allowed_concepts": ["assignment", "input", "print"],
  "forbidden_concepts": ["import"],
  "hint_ladder": [
    "先用一個變數把輸入存下來。",
    "確認變數名稱前後一致。",
    "最後才把結果印出。"
  ],
  "common_mistakes": [
    {
      "pattern": "variable-name-mismatch",
      "diagnosis": "宣告與使用的變數名稱不一致",
      "hint": "把每個使用處對齊到同一個名稱"
    }
  ],
  "refusal_rules": [
    "不要直接給完整答案"
  ],
  "answer_style": {
    "tone": "clear",
    "max_steps": 3,
    "max_response_length": 500
  },
  "metadata": {
    "owner": "teaching-team"
  }
}
```

## 8. 與 Level YAML 的關聯

在 `assets/levels/<level>.yaml` 以 `teaching_skill_ids` 指定技能，例如：

```yaml
teaching_skill_ids:
  - input-output-basics

tutor_policy:
  allow_full_solution: false
  max_hint_steps: 3
  response_tone: clear
```

loader 會將這些欄位帶入 `LevelSpec`，供 Tutor 流程使用。

## 9. 驗證建議

新增或修改 skill 後，至少執行：

```powershell
c:/Users/tange/Desktop/all_project/比賽/Block2Python/.venv/Scripts/python.exe -m pytest tests/ai/test_teaching_skill_loader.py tests/test_levels_loader.py
```

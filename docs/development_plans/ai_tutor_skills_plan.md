# AI 助教 Skills 計畫

- 版本：0.1
- 日期：2026-03-08
- 相關文件：
  - `docs/requirements.md`
  - `docs/project_plan.md`
  - `docs/development_plans/mvp_development_plan.md`
  - `docs/technical_rationale.md`

## 0. 目標

本文件用來定義 Block2Python 中「AI 助教」這一側的 skill 架構應該如何落地。

目前專案的開發用 skill 架構已經建立完成，但學生互動用的 AI 助教部分還沒有正式成形。接下來需要把 skill 從「團隊開發輔助工具」延伸成「學生提問時可依循的穩定教學規範」，同時維持與開發用 skill 的明確分界。

本文件重點處理：

- Demo 階段可落地的 AI 助教最小架構
- 教學頁內容與 teaching skills 的邊界
- 從關卡內容到 AI 回覆的資料流
- teaching skill 的資料格式與載入策略
- 對應目前程式碼現況的實作順序

## 1. 目前狀態

根據目前 repo 的實際狀態：

- `src/block2python/ai/` 已存在，但幾乎還是空的
- `LevelSpec` 已經具備可承接 AI 助教上下文的欄位：
  - `prompt`
  - `learning_markdown`
  - `story_intro_markdown`
  - `story_outro_markdown`
  - `analysis_policy`
  - `concept_policy`
  - `metadata`
- 關卡內容目前集中在 `assets/levels/*.json`，因此 tutor 相關資料可以從內容層擴充，不必先把規則寫死在 Python 程式碼裡
- UI 已經有教學/劇情顯示區塊，所以後續可以再加 tutor 面板
- `AstAnalyzer` 已經做了部分範圍限制，後續可以直接拿來支援 tutor 的回答邊界

這代表下一步不應該是「先接模型」，而應該先把 AI 助教的資料契約、teaching skill 格式、與回答邊界設計清楚。

## 2. 設計原則

### 2.1 開發用 Skills 與教學用 Skills 必須分開

這兩類 skill 不應混在一起。

- 開發用 skills：
  - 給專案團隊使用
  - 由 `.agent/skills/` 的 canonical skill 架構管理
  - 目的在於實作、規劃、維護與文件協作

- 教學用 skills：
  - 給 AI 助教在學生提問時使用
  - 應視為 app runtime 內容或設定，而不是團隊 workflow skill
  - 目的在於限制回答邊界、穩定提示品質、維持概念範圍一致

建議做法：

- 開發用 skills 持續放在 `.agent/skills/`
- 教學用 skills 另放於 app 自己的內容區，例如：
  - `assets/teaching_skills/`

這樣可以避免團隊內部提示與學生面向的教學規範互相污染。

### 2.2 以結構化檢索為主，不用巨大自由 prompt

AI 助教的回覆不應該依賴一大段自由撰寫的 prompt，而應該根據「當前關卡」組裝出的結構化上下文來回答。

建議上下文優先順序：

1. 當前 `LevelSpec`
2. 與當前關卡對應的 teaching skill
3. 最新的 analysis 結果與 judge 結果
4. 學生的 Python 程式碼與 block JSON
5. 後續若有需要，再考慮少量對話歷史

這樣可以讓 AI 助教更穩定地被限制在當前關卡範圍內，減少「好像很有幫助但其實超綱」的回答。

### 2.3 以提示為主，不直接給完整解答

AI 助教應被明確限制為：

- 解釋當前關卡內的概念
- 指出常見錯誤與可能方向
- 提供下一步提示或部分引導
- 在學生直接索取完整答案時拒絕

系統層應至少區分：

- 可提供的協助
- 限制型協助
- 必須拒絕的協助

## 3. 建議架構

### 3.1 主要元件

建議在 `src/block2python/ai/` 下建立最小可用的 tutor 層：

- `models.py`
  - tutor request / response dataclass
- `teaching_skill_loader.py`
  - 載入 teaching skill 檔案
- `context_builder.py`
  - 將 level、analysis、judge、submission 組成 tutor context
- `policy.py`
  - 套用回答邊界、拒答規則、提示策略
- `service.py`
  - 提供 app / UI 呼叫的公開入口
- `providers/`
  - 模型供應者抽象層；第一階段先放 stub provider

建議第一版公開 API 形式：

```python
TutorReply = tutor_service.reply(
    level=level_spec,
    submission=submission,
    analysis=analysis_result,
    judge=judge_result,
    user_question=question,
)
```

### 3.2 Teaching Skill 結構

teaching skill 不建議直接依賴外部 agent-skill runner 格式，而應該採用 app 自己能直接載入、驗證、測試的 schema。

建議檔案位置：

- `assets/teaching_skills/index.json`
- `assets/teaching_skills/<skill-id>.json`

建議最小 schema：

```json
{
  "skill_id": "input-output-basics",
  "title": "輸入輸出基礎",
  "applies_to": {
    "level_ids": ["demo-1"],
    "concepts": ["input", "print", "int"]
  },
  "student_level": "beginner",
  "learning_goals": [
    "理解如何讀取一行輸入",
    "理解如何輸出計算結果"
  ],
  "allowed_concepts": ["input", "print", "int", "+"],
  "forbidden_concepts": ["while", "def", "list", "import"],
  "hint_ladder": [
    "先想清楚你要先讀進來哪些值。",
    "提醒：input() 讀到的是文字。",
    "在做加法前，先確認型別有沒有轉換。"
  ],
  "common_mistakes": [
    {
      "pattern": "把字串直接相加",
      "diagnosis": "你可能還沒把輸入轉成整數。",
      "hint": "檢查加法前是否有做型別轉換。"
    }
  ],
  "refusal_rules": [
    "不要直接提供完整最終解答。",
    "不要引入超出 allowed_concepts 的新概念。"
  ],
  "answer_style": {
    "tone": "clear",
    "max_steps": 3
  }
}
```

這個格式故意設計成 app 專用，因為 runtime tutor 比開發期 skill 更需要穩定、可測、可版本控制的資料格式。

### 3.3 Tutor Context 物件

每次 AI 助教回覆前，應先建立一個標準化的 tutor context：

- 關卡身分資訊：
  - `level_id`
  - `title`
  - `prompt`
- 教學內容：
  - `learning_markdown`
  - 當前 learning goals
- teaching skill 內容：
  - allowed concepts
  - forbidden concepts
  - hint ladder
  - common mistakes
  - refusal rules
- 學生狀態：
  - 使用者提問
  - 當前 Python 程式碼
  - 當前 block JSON
  - block schema version
- 系統訊號：
  - analysis status
  - analysis violations
  - judge status
  - failed case 摘要

這個 context 應成為 tutor 生成回覆的唯一可信來源。

## 4. 教學頁與 Teaching Skill 的分工

這個分工必須盡早固定，否則後續內容會混亂。

### 4.1 教學頁應負責

- 學生直接閱讀的教學內容
- 題目前導說明與概念介紹
- 範例、圖示、劇情文本
- 關卡目標的呈現

### 4.2 Teaching Skill 應負責

- AI 回答邊界
- 提示順序與提示階梯
- 常見錯誤對應規則
- 拒答規則
- 用詞統一
- 當前關卡允許 / 禁止概念

### 4.3 實務判準

如果某段內容主要是給學生在操作前或操作中閱讀，那它應該放在教學頁。

如果某段內容主要是控制 AI 應該怎麼回答，那它應該放在 teaching skill。

## 5. 建議資料流

AI 助教流程建議如下：

1. 學生選擇關卡
2. UI 載入 `LevelSpec`
3. 學生在 tutor 面板提問
4. app 收集：
   - 當前 level
   - 當前 submission draft
   - 最近一次 analysis / judge 結果（如果有）
   - 對應的 teaching skill
5. `context_builder` 組出標準化 tutor context
6. `policy` 判斷回覆模式：
   - 概念提示
   - debug 提示
   - 拒答
7. provider 根據結構化 context 產生回覆
8. UI 顯示回覆，必要時顯示回覆類型標記

建議的回覆模式：

- `concept_explanation`
- `next_step_hint`
- `debug_hint`
- `scope_refusal`
- `solution_refusal`

## 6. Level / 內容 Schema 擴充建議

現有 level schema 已經能承接很多資訊，但若要讓 tutor 接得更乾淨，建議增加幾個欄位。

建議 level JSON 可選欄位：

```json
{
  "teaching_skill_ids": ["input-output-basics"],
  "tutor_policy": {
    "allow_full_solution": false,
    "max_hint_steps": 3
  }
}
```

建議規則：

- level JSON 決定這關套用哪些 teaching skill
- teaching skill 定義提示策略與回答邊界
- `analysis_policy` 仍聚焦於靜態分析規則
- `concept_policy` 應逐步成為 app 內 canonical 的概念邊界欄位

對目前程式碼的建議是：

- 暫時保留既有 `metadata["analysis"]` hook
- 逐步把概念邊界資料從 `metadata` 提升為明確的 `concept_policy`
- `teaching_skill_ids` 專門用來做 tutor 內容選取

## 7. 與現有 Analysis / Judge 的整合

AI 助教不應該自己猜學生哪裡錯，而應該盡量利用系統既有輸出。

### 7.1 來自 Analysis

`AnalysisResult` 可用來產生：

- syntax error 導向提示
- forbidden concept 提醒
- required keyword 缺漏提醒

例如：

- 如果 analysis 顯示缺少 required keyword，AI 應提示學生「這題需要哪種結構」，而不是直接把完整程式碼寫出來

### 7.2 來自 Judge

`JudgeResult` 可用來產生：

- failed case 導向提示
- 輸出不符的檢查方向
- input / output 格式檢查提醒

### 7.3 尚未送出時的 fallback

如果學生在 submit 前就提問：

- AI 仍可根據教學頁與 teaching skill 回答概念問題
- 但不應假裝自己已經看到執行錯誤或測資結果

## 8. Provider 策略

第一版不要直接綁定遠端模型。

建議順序：

1. `StubTutorProvider`
   - 輸出可預期、可重現
   - 足夠支援 UI 串接、schema 驗證、Demo 展示
2. `TemplateTutorProvider`
   - 根據 analysis / judge / teaching skill 規則產生模板式回覆
   - 仍不依賴外部模型
3. 遠端 LLM provider
   - 等回答邊界、context schema、UI 行為穩定後再接

這個順序很重要，因為目前專案真正缺的不是「模型接口」，而是「受控的 tutor 行為設計」。

## 9. UI 計畫

目前 `MainWindow` 已經有 prompt、learning、story 與 feedback 區塊。

建議新增：

- 一個 tutor 面板，放在 feedback 下方或旁邊
- 包含：
  - 問題輸入框
  - `Ask Tutor` 按鈕
  - tutor 回覆顯示區
  - 視需要顯示回覆模式標記

建議 MVP 互動方式：

- 一次問一個問題
- Phase 1 不做長對話歷史
- 只使用當前關卡上下文

這樣第一版最容易驗證，也能避免跨關卡上下文污染。

## 10. 分階段實作

### Phase 1：定義 Teaching Skill 內容模型

- 建立 teaching skill JSON schema 與 loader
- 在 `assets/teaching_skills/` 放 1 到 2 份 sample skill
- 在 demo levels 加上 `teaching_skill_ids`
- provider 先保持 stub

完成標準：

- app 能載入 teaching skill，並解析出某關卡對應的 skill

### Phase 2：先做不依賴 LLM 的 Tutor Service

- 建立 tutor request / response models
- 建立 context builder
- 建立 policy layer
- 實作 `StubTutorProvider` 或 `TemplateTutorProvider`

完成標準：

- app 能根據 level + teaching skill + analysis/judge 輸出穩定提示

### Phase 3：UI 串接

- 在 `MainWindow` 增加 tutor 輸入/輸出區
- 將當前 code、level、最近 feedback 串進 tutor request
- 清楚呈現拒答訊息

完成標準：

- 本機 UI demo 可展示 tutor 提示流程

### Phase 4：強化邊界

- 擴充 `concept_policy`
- 補測試，確認：
  - 不會洩漏完整解答
  - 不會超出當前關卡概念範圍
  - 已知輸入下回覆可預測

完成標準：

- tutor 行為可測且與關卡範圍一致

### Phase 5：選配接入真實模型

- 在 feature flag 後面新增 provider adapter
- 維持 context 組裝邏輯不變
- 維持 provider 前的 policy / refusal 檢查

完成標準：

- 即使接入模型，也不破壞 app 自己定義的 tutor contract

## 11. 測試策略

最低限度測試建議：

- loader tests：
  - teaching skill 檔案格式錯誤
  - level 指向不存在的 teaching skill
  - level 與 skill 的解析關係正確
- policy tests：
  - 會拒絕直接索取完整答案
  - 會拒絕超綱問題
  - 學生卡住時會使用 hint ladder
- service tests：
  - syntax error 會產生 syntax 導向提示
  - WA 會產生 debug 導向提示
  - 尚未 submit 時仍可回答概念問題
- UI smoke test：
  - 選關後提問，能顯示 tutor 回覆

## 12. 建議第一刀

對這個 repo 來說，最合理的第一個 vertical slice 是：

1. 建立 `docs/development_plans/ai_tutor_skills_plan.md`
2. 建立 `assets/teaching_skills/`，先放 `demo-1`、`demo-2` 的 sample skill
3. 在 `src/block2python/ai/` 補上 loader 與 models
4. 加一個 stub / template tutor service
5. 在 UI 加一個最小 tutor 面板

這樣就能先做出不依賴外部模型的可展示版本。

## 13. 核心決策

建議正式採納的決策如下：

1. teaching skills 應該是 app 內容，不應混進 `.agent/skills/`
2. runtime tutor 應使用專案自有 schema，而不是直接沿用開發 skill 格式
3. AI tutor 應由結構化 context 驅動，而不是依賴單一自由 prompt
4. 第一個 provider 應是 stub / template provider，而不是直接接遠端 LLM
5. 教學頁內容與 teaching skill 內容必須有清楚責任切分

## 14. 風險

- 如果 teaching skills 與開發 skills 混管，後續維護邊界會很快失控
- 如果在 schema / policy 尚未穩定前就先接遠端模型，回答行為會漂移且難以測試
- 如果 tutor 不使用 analysis / judge 結果，回覆很容易變成空泛建議，甚至與系統實際判定衝突
- 如果太早加入長對話記憶，跨關卡污染與回答失控的風險會大幅上升

## 15. 下一步

如果接受這份計畫，建議下一個實作任務直接做 Phase 1 + Phase 2 的薄切片：

- 補 teaching skill 檔案
- 補 loader
- 補 tutor service
- 補 stub / template provider
- 在 UI 先接一個最小入口

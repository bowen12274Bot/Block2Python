# Godot Client Contract Surface

- 版本：0.1
- 日期：2026-03-15
- 狀態：草案
- 文件定位：明文化目前 Godot client 對 integration contract 的最小依賴面

## 1. 目的

本文件不是 bridge protocol 規格，也不是 `GameState` 的完整 schema。

本文件只回答一件事：
目前 Godot client 骨架，正式依賴 `GameState` 的哪些欄位，並透過 `StateMapper` 收斂成哪些 view model。

這份文件的用途是：

- 避免 Godot 端直接散落依賴 raw dictionary 欄位
- 讓 Python 端之後調整 contract 時，知道哪些欄位已成為 Godot 正式依賴
- 作為 `QuestMapController / MainController -> Panels` 的共同邊界說明

## 2. 分層原則

依賴順序應固定為：

1. Python bridge 回傳 response envelope
2. `GameState` raw dictionary
3. `StateMapper`
4. Godot view model
5. `QuestMapController` / `MainController`
6. `QuestMapPanel` / `ScenePanel` / `ChallengePanel` / `FeedbackPanel`

Godot panel 不應直接解析 raw `GameState`。

## 3. Godot 端目前正式依賴的 response 欄位

### 3.1 Response Envelope

Godot 端目前正式依賴以下 top-level response 欄位：

- `ok`
- `state`
- `error`

`debug` 目前只作為開發期 debug panel 顯示，不屬於正式 UI 依賴面。

### 3.2 GameState 最小依賴欄位

目前 `StateMapper` 正式依賴以下 `GameState` 欄位：

- `mode`
- `quest_id`
- `node_id`
- `node_title`
- `scene`
- `challenge`
- `available_actions`
- `last_submission`

目前未作為正式 Godot UI 必要依賴的欄位：

- `progress`
- `errors`
- `available_actions.restart_quest`

## 4. 子結構依賴面

### 4.1 Scene

目前 `scene_view` 依賴：

- `scene.title`
- `scene.dialogue_blocks[*].speaker`
- `scene.dialogue_blocks[*].text`

目前未使用但保留在 contract 的欄位：

- `portrait_id`
- `expression`
- `emphasis`

### 4.2 Challenge

目前 `challenge_view` 依賴：

- `challenge.current_level_title`
- `challenge.current_level_id`
- `challenge.current_level_prompt`

目前未使用但仍存在於 contract 的欄位：

- `challenge.challenge_id`
- `challenge.challenge_type`

### 4.3 Available Actions

目前 `action_view` 依賴：

- `available_actions.advance`
- `available_actions.submit`

### 4.4 Last Submission

目前 `feedback_view` 依賴：

- `last_submission.level_id`
- `last_submission.cleared`
- `last_submission.analysis_status`
- `last_submission.analysis_summary`
- `last_submission.judge_status`
- `last_submission.judge_summary`

目前未作為 UI 呈現必要欄位：

- `last_submission.block_passed`

## 5. StateMapper 輸出 shape

目前 `StateMapper.map_game_state()` 輸出固定為：

```text
view_model
- meta
- scene_view
- challenge_view
- feedback_view
- action_view
```

### 5.1 meta

用途：保存主流程共用的節點與模式資訊。

目前欄位：

- `mode`
- `quest_id`
- `node_id`
- `node_title`

### 5.2 scene_view

用途：提供 `ScenePanel` 專用顯示資料。

目前欄位：

- `mode_label`
- `node_label`
- `title`
- `body`

### 5.3 challenge_view

用途：提供 `ChallengePanel` 專用顯示資料。

目前欄位：

- `title`
- `level_label`
- `prompt_body`
- `code_editable`

### 5.4 feedback_view

用途：提供 `FeedbackPanel` 專用顯示資料。

目前欄位：

- `title`
- `body`

### 5.5 action_view

用途：提供 `MainController` 控制按鈕狀態。

目前欄位：

- `can_advance`
- `can_submit`

## 6. 目前面板依賴關係

### 6.0 QuestMapPanel

只吃：

- quest map 專用 view model

不應直接讀：

- raw `state.progress`
- raw `state.node_id`

### 6.1 ScenePanel

只吃：

- `scene_view`

不應直接讀：

- raw `state.scene`
- raw `state.mode`

### 6.2 ChallengePanel

只吃：

- `challenge_view`

另外暴露：

- `get_python_code()`

### 6.3 FeedbackPanel

只吃：

- `feedback_view`

### 6.4 MainController

負責：

- 接收 bridge response
- 呼叫 `StateMapper`
- 分發 `scene_view / challenge_view / feedback_view`
- 根據 `action_view` 控制按鈕

不應再回退成直接組字串或散落讀 raw `state.get(...)`。

### 6.5 QuestMapController

負責：

- 接收 bridge response
- 驅動 quest map refresh
- 透過 `StateMapper` 分發 flow panels
- 控制 `Start Bridge / Reset / Advance / Submit`

不應直接讓 `QuestMapPanel` 或 `ChallengePanel` 自行解析 raw `GameState`。

## 7. 後續變更原則

之後若 Python 端想調整 contract，請先區分兩種層級：

1. 可自由調整但不影響 Godot 正式依賴面
   - 例如額外新增欄位
   - 例如 `debug` payload 結構調整

2. 會影響 Godot 正式依賴面
   - 刪除或改名本文件列出的欄位
   - 改動 `StateMapper` 既有輸出 shape
   - 改動 `ScenePanel / ChallengePanel / FeedbackPanel` 已依賴的 view model key

若屬於第 2 類，應同步更新：

- `StateMapper`
- 對應 panel
- 本文件
- 必要時更新 `godot_client_structure_plan.md`

## 8. 目前結論

目前 Godot client 已不再直接依賴完整 raw `GameState`。

正式依賴面已收斂為：

- response envelope 的 `ok / state / error`
- `GameState` 中少量穩定欄位
- `StateMapper` 定義的固定 view model shape

這代表之後要進一步做正式 UI、美術與互動擴充時，可以先維持這層邊界不變，再在 Godot 端持續演進畫面與控制流程。

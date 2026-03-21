# Godot Client Contract Surface

- 版本：0.2
- 日期：2026-03-22
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

- `scene.scene_id`
- `scene.title`
- `scene.dialogue_blocks[*].speaker`
- `scene.dialogue_blocks[*].text`
- `scene.dialogue_blocks[*].portrait_id`
- `scene.dialogue_blocks[*].expression`
- `scene.dialogue_blocks[*].emphasis`
- `scene.dialogue_blocks[*].speaker_side`
- `scene.dialogue_blocks[*].background_id`
- `scene.dialogue_blocks[*].left_actor`
- `scene.dialogue_blocks[*].right_actor`

目前仍視為資料層保留欄位，但 Godot 端先不做資源解析：

- `background.image_path`
- `left_actor.image_path`
- `right_actor.image_path`

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

- `last_submission.stdout`
- `last_submission.stderr`

## 5. Mapper 輸出的正式 view model 介面

### 5.1 scene_view

過渡期 `scene_view` 同時保留舊版文字摘要欄位與新版劇情演出資料骨架：

```yaml
scene_view:
  mode_label: "Mode: scene"
  node_label: "Node: story-intro"
  title: "City Alarm"
  body: "- Byte: ..."
  scene_id: "scene-city-alarm"
  current_index: 0
  total_blocks: 3
  can_advance: true
  background:
    background_id: "city-alarm-room"
    image_path: ""
  left_actor:
    actor_id: "byte"
    portrait_id: "byte-default"
    image_path: ""
    pose_id: "default"
    expression_id: "alert"
    visual_state: "focus"
    display_name: "Byte"
  right_actor:
    actor_id: "player"
    portrait_id: "player-default"
    image_path: ""
    pose_id: "default"
    expression_id: "surprised"
    visual_state: "dim"
    display_name: "Player"
  dialogue:
    speaker: "Byte"
    text: "城市警報響起了！"
    emphasis: "warning"
    speaker_side: "left"
  dialogue_blocks:
    - speaker: "Byte"
      text: "城市警報響起了！"
  continue_hint_text: "點擊繼續"
```

說明：

- `mode_label`、`node_label`、`title`、`body` 保留給既有文字型 scene panel 使用
- `scene_id`、`current_index`、`total_blocks`、`can_advance` 提供劇情流程控制資訊
- `background`、`left_actor`、`right_actor`、`dialogue`、`dialogue_blocks`、`continue_hint_text` 為正式劇情頁資料骨架

### 5.2 challenge_view

```yaml
challenge_view:
  mode_label: "Mode: challenge"
  node_label: "Node: demo-basic-io"
  title: "Challenge"
  level_id: "level-basic-input"
  prompt: "請完成輸入與輸出"
```

### 5.3 action_view

```yaml
action_view:
  can_advance: true
  can_submit: false
```

### 5.4 feedback_view

```yaml
feedback_view:
  status_label: "Passed"
  summary: "輸出正確"
```

## 6. Panel 責任邊界

### 6.1 QuestMapPanel

只應消費 map / node 相關 view model，不應直接知道 scene raw payload。

### 6.2 ScenePanel

過渡期可同時消費：

- 舊版 `title` + `body` 文字欄位
- 新版劇情演出資料骨架 `background / left_actor / right_actor / dialogue / continue_hint_text`

ScenePanel 不應自行回推 `speaker_side`、角色焦點或背景切換規則。

### 6.3 ChallengePanel

只應消費 `challenge_view`，不應自行解析 `state.challenge`。

### 6.4 FeedbackPanel

只應消費 `feedback_view`，不應自行推導評測摘要。

## 7. 變更控制原則

若 Python 端要調整 contract：

1. 先更新本文件
2. 再更新 `StateMapper`
3. 最後更新 Godot panel

不要讓 panel 直接依賴新增 raw 欄位後再補文件。

## 8. 結論

目前 Godot client 的 scene flow 依賴面，已從單純文字摘要擴充為正式劇情頁資料骨架。

後續若要接開場劇情、地圖 story 節點與未來結局劇情，應持續沿著 `GameState -> StateMapper -> view model -> panel` 這條路徑演進。
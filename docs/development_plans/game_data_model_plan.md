# 遊戲最小資料模型計畫

- 文件版本：0.1
- 更新日期：2026-03-14
- 文件定位：定義第一階段遊戲化轉型所需的最小資料模型與存檔主責

## 1. 目的

本文件用於將第一個 vertical slice 所需的狀態，壓成可落地的資料模型。

目標不是一次定義完整最終 schema，而是先定義足以支撐第一個 vertical slice 的最小集合。

## 2. 設計原則

- 遊戲資料與挑戰資料分層
- 存檔只保存恢復流程所需的必要狀態
- 示範關與練習關共用挑戰核心，但遊戲層要能辨識兩者角色差異
- 練習關整組狀態不得退化為單題通關旗標

## 3. 最小模型清單

### 3.1 NodeSpec

用途：

- 表示主地圖上的一個節點

至少需要：

- `node_id`
- `node_type`（story / demo / practice / result）
- `title`
- `prerequisite_node_ids`
- `next_node_ids`
- `scene_id` 或 `challenge_group_id`

欄位草案：

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `node_id` | `str` | 是 | 節點唯一識別 |
| `node_type` | `str` | 是 | `entry` / `story` / `demo` / `practice` / `result` |
| `title` | `str` | 是 | 節點顯示名稱 |
| `prerequisite_node_ids` | `list[str]` | 否 | 進入前需完成的節點 |
| `next_node_ids` | `list[str]` | 否 | 成功後可導向的節點 |
| `scene_id` | `str | null` | 否 | 若為劇情節點，對應場景 |
| `challenge_group_id` | `str | null` | 否 | 若為關卡節點，對應挑戰群組 |

第一個 slice 對應：

- `map-entry`
- `story-intro`
- `demo-basic-io`
- `practice-basic-io`
- `result-basic-io`
- `next-main-node`

### 3.2 QuestSpec

用途：

- 表示一段可辨識的任務或章節流程

至少需要：

- `quest_id`
- `title`
- `node_ids`
- `entry_node_id`
- `completion_node_id`

欄位草案：

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `quest_id` | `str` | 是 | 任務唯一識別 |
| `title` | `str` | 是 | 任務名稱 |
| `node_ids` | `list[str]` | 是 | 任務包含的節點 |
| `entry_node_id` | `str` | 是 | 任務入口節點 |
| `completion_node_id` | `str` | 是 | 任務完成節點 |

第一個 slice 對應：

- `quest-basic-io-repair`

### 3.3 SceneSpec

用途：

- 承載劇情 / 對話段落

至少需要：

- `scene_id`
- `title`
- `dialogue_blocks`
- `next_action`

欄位草案：

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `scene_id` | `str` | 是 | 場景唯一識別 |
| `title` | `str` | 是 | 場景名稱 |
| `dialogue_blocks` | `list[dict]` | 是 | 對話內容區塊 |
| `next_action` | `str` | 是 | 場景結束後的下一步動作 |

第一個 slice 對應：

- `scene-city-alarm`
- `scene-practice-unlock`
- `scene-result-success`
- `scene-result-fail`

### 3.4 ChallengeSpec

用途：

- 對遊戲層提供一個抽象挑戰入口
- 內部可映射到現有 `LevelSpec` 或其後繼模型

至少需要：

- `challenge_id`
- `challenge_type`（demo / practice）
- `level_ids`
- `toolbox_policy_id`
- `battery_policy_id`

欄位草案：

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `challenge_id` | `str` | 是 | 挑戰群組識別 |
| `challenge_type` | `str` | 是 | `demo` / `practice` |
| `level_ids` | `list[str]` | 是 | 對應現有 level 或其後繼 ID |
| `toolbox_policy_id` | `str | null` | 否 | 工具包規則識別 |
| `battery_policy_id` | `str | null` | 否 | 能量規則識別 |

第一個 slice 對應：

- `challenge-demo-basic-io`
- `challenge-practice-basic-io`

### 3.5 ToolboxSpec

用途：

- 表示目前可用的積木集合與工具包使用規則

至少需要：

- `toolbox_id`
- `unlocked_block_ids`
- `allow_toolbox_in_practice`
- `toolbox_reward_percent`

欄位草案：

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `toolbox_id` | `str` | 是 | 工具包規則識別 |
| `unlocked_block_ids` | `list[str]` | 是 | 目前可用積木 |
| `allow_toolbox_in_practice` | `bool` | 是 | 是否允許在練習關開啟 |
| `toolbox_reward_percent` | `int` | 是 | 開啟工具包後單題獎勵 |

### 3.6 BatteryPolicy / BatteryState

用途：

- 表示能量規則與當前累積狀態

`BatteryPolicy` 至少需要：

- `full_reward_percent`
- `toolbox_reward_percent`
- `pass_threshold_percent`
- `accepted_pass_values`

`BatteryState` 至少需要：

- `current_percent`
- `per_question_rewards`
- `passed`

欄位草案：

`BatteryPolicy`

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `full_reward_percent` | `int` | 是 | 未使用工具包時單題獎勵 |
| `toolbox_reward_percent` | `int` | 是 | 使用工具包時單題獎勵 |
| `pass_threshold_percent` | `int` | 是 | 通關門檻基準 |
| `accepted_pass_values` | `list[int]` | 是 | 實際接受的過關值 |

`BatteryState`

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `current_percent` | `int` | 是 | 當前總能量 |
| `per_question_rewards` | `list[int]` | 是 | 每題實際獎勵結果 |
| `passed` | `bool` | 是 | 是否達成過關條件 |

### 3.7 PracticeRunState

用途：

- 表示固定 5 題練習關的整組狀態

至少需要：

- `practice_run_id`
- `challenge_id`
- `question_index`
- `question_results`
- `toolbox_used_flags`
- `battery_state`
- `cooldown_until`
- `completed`
- `passed`

欄位草案：

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `practice_run_id` | `str` | 是 | 練習關執行識別 |
| `challenge_id` | `str` | 是 | 對應的練習關群組 |
| `question_index` | `int` | 是 | 目前進度 |
| `question_results` | `list[dict]` | 是 | 各題完成狀態摘要 |
| `toolbox_used_flags` | `list[bool]` | 是 | 各題是否使用過工具包 |
| `battery_state` | `BatteryState` | 是 | 目前能量狀態 |
| `cooldown_until` | `str | null` | 否 | 冷卻截止時間 |
| `completed` | `bool` | 是 | 是否跑完整組 |
| `passed` | `bool` | 是 | 是否整組通過 |

第一個 slice 對應：

- `practice-run-basic-io`

### 3.8 SaveGame

用途：

- 作為遊戲進度的主存檔模型

至少需要：

- `save_version`
- `current_node_id`
- `unlocked_node_ids`
- `completed_node_ids`
- `completed_challenge_ids`
- `toolbox_state`
- `practice_run_states`
- `story_flags`

欄位草案：

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `save_version` | `str` | 是 | 存檔版本 |
| `current_node_id` | `str` | 是 | 目前所在節點 |
| `unlocked_node_ids` | `list[str]` | 是 | 已解鎖節點 |
| `completed_node_ids` | `list[str]` | 是 | 已完成節點 |
| `completed_challenge_ids` | `list[str]` | 否 | 已完成 challenge 群組 |
| `toolbox_state` | `dict` | 是 | 工具包解鎖資訊 |
| `practice_run_states` | `list[PracticeRunState]` | 否 | 練習關整組狀態 |
| `story_flags` | `dict[str, bool]` | 否 | 劇情旗標 |

第一個 slice 最小保存狀態：

- 目前節點
- 是否完成示範關
- 5 題練習關整組狀態
- 是否解鎖下一節點
- 是否正在冷卻

## 4. 存檔主責原則

### 4.1 由遊戲存檔主責保存的狀態

- 目前所在節點
- 節點解鎖與完成狀態
- 劇情旗標
- 工具包解鎖狀態
- 練習關整組進度
- 冷卻時間
- 電池結算結果

### 4.2 由挑戰核心即時計算、但不必直接主責保存的狀態

- 單次提交的分析結果
- 單次提交的 judge 結果
- 當次題目的原始 stderr / stdout
- 細部 case-by-case debug 資訊

### 4.3 Bridge 層的角色

- 將挑戰核心輸出的結果轉成可持久化狀態
- 決定哪些資料進 `SaveGame`
- 避免遊戲前端直接理解 judge 細節

## 5. 與現有模型的關係

- 現有 `LevelSpec` 可視為 `ChallengeSpec` 之下的挑戰內容來源
- 現有 progress 機制只能作為過渡方案，無法直接承接 `PracticeRunState` 與 `BatteryState`
- 後續應將現有 `AppCore` 抽成更明確的 challenge engine，再由 Bridge 與 `SaveGame` 整合

## 6. 第一階段不急著定死的部分

- 完整章節 schema
- 多分支任務系統
- 完整 NPC 關係模型
- 雲端存檔格式
- AI tutor 對話歷史保存格式

## 7. 下一步

- 根據本文件補一版更接近實作的 schema 草案
- 將第一個 vertical slice 的節點、場景與挑戰內容映射到上述模型
- 根據存檔主責原則，重做現有 progress abstraction

## 8. 第一版 schema 化順序

1. 先定 `NodeSpec`、`SceneSpec`、`ChallengeSpec`
2. 再定 `PracticeRunState`、`BatteryState`
3. 最後整合進 `SaveGame`

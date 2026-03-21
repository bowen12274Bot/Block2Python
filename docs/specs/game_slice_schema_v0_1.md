# 遊戲第一個切片 Schema 規格（v0.1）

- 文件版本：0.2
- 更新日期：2026-03-22
- 適用範圍：第一個遊戲化 vertical slice
- 文件定位：定義第一個切片所需的最小資料格式，作為內容、Bridge 與存檔的共同資料語言

## 1. 目的

本文件用於將 `game_vertical_slice_plan.md`、`game_data_model_plan.md` 與 `game_system_boundary_plan.md` 中已確認的內容，壓成第一版可落地 schema。

本文件不是完整最終遊戲 schema，只覆蓋第一個切片真正會用到的部分。

## 2. 設計原則

- 優先支撐第一個可玩切片，不超前設計多章節需求
- 遊戲節點、劇情場景、挑戰群組、練習關狀態與存檔彼此分層
- 欄位名稱以穩定、可讀與可擴充為優先
- 範例使用 YAML，後續可再轉為 JSON、dataclass 或正式驗證 schema
- 對話欄位採保留並擴充策略，延續既有欄位並新增正式劇情頁需要的最小資料

## 3. 參考樣板

本文件只保留欄位契約與設計邊界。

完整 YAML 樣板請直接參考：

- `docs/specs/examples/scene-*.yaml`
- `docs/specs/examples/toolbox-example.yaml`
- `docs/specs/examples/battery-policy-example.yaml`
- `docs/specs/examples/savegame.example.yaml`

## 4. NodeSpec

用途：

- 定義主地圖上的節點與節點間流向

### 4.1 欄位

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `node_id` | `str` | 是 | 節點唯一識別 |
| `node_type` | `str` | 是 | `entry` / `story` / `demo` / `practice` / `result` |
| `title` | `str` | 是 | 顯示名稱 |
| `prerequisite_node_ids` | `list[str]` | 否 | 進入前需完成的節點 |
| `next_node_ids` | `list[str]` | 否 | 成功後可導向的節點 |
| `scene_id` | `str | null` | 否 | 劇情節點對應場景 |
| `challenge_group_id` | `str | null` | 否 | 關卡節點對應 challenge group |

## 5. SceneSpec

用途：

- 定義劇情與任務說明段落

### 5.1 欄位

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `scene_id` | `str` | 是 | 場景唯一識別 |
| `title` | `str` | 是 | 場景名稱 |
| `dialogue_blocks` | `list[DialogueBlock]` | 是 | 對話內容 |
| `next_action` | `str` | 是 | 場景結束後的動作 |

### 5.2 DialogueBlock

用途：

- 定義對話框中單一段可播放內容

#### 5.2.1 欄位

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `speaker` | `str` | 是 | 說話者識別或顯示名稱 |
| `text` | `str` | 是 | 對話文字 |
| `portrait_id` | `str | null` | 否 | 舊版角色立繪識別，保留作為相容欄位 |
| `expression` | `str | null` | 否 | 舊版表情識別，保留作為相容欄位 |
| `emphasis` | `str | null` | 否 | 舊版文字強調語氣，保留作為相容欄位 |
| `speaker_side` | `str | null` | 否 | 發話者站位，第一版使用 `left` / `right` / `center` |
| `background_id` | `str | null` | 否 | 當前段落要使用的背景識別 |
| `left_actor` | `ActorSlotSpec | null` | 否 | 左側角色槽狀態 |
| `right_actor` | `ActorSlotSpec | null` | 否 | 右側角色槽狀態 |

### 5.3 ActorSlotSpec

用途：

- 描述單一角色槽在某段對話中的最小呈現狀態

#### 5.3.1 欄位

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `actor_id` | `str` | 是 | 角色識別 |
| `pose_id` | `str | null` | 否 | 姿勢識別 |
| `expression_id` | `str | null` | 否 | 表情識別 |
| `visual_state` | `str` | 是 | `hidden` / `dim` / `focus` / `silhouette` |

### 5.4 第一版暫不固定的 Scene 欄位

以下欄位不在第一版 schema 強制要求內：

- `voice_id`
- `bgm_cue`
- `sfx_cue`
- `camera_cue`
- `transition_cue`
- `choices`
- `next_scene_id`

## 6. ChallengeGroupSpec

用途：

- 定義一組關聯 challenge 與其進入順序

### 6.1 欄位

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `challenge_group_id` | `str` | 是 | 挑戰群組唯一識別 |
| `title` | `str` | 是 | 顯示名稱 |
| `challenge_ids` | `list[str]` | 是 | 依序收錄的 challenge |
| `unlock_strategy` | `str` | 是 | 例如 `sequential` |

## 7. ChallengeSpec

用途：

- 定義單一 demo 或 practice 關卡內容

### 7.1 欄位

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `challenge_id` | `str` | 是 | 關卡唯一識別 |
| `challenge_type` | `str` | 是 | `demo` / `practice` |
| `title` | `str` | 是 | 關卡名稱 |
| `level_ids` | `list[str]` | 是 | 對應教材 level |
| `success_result_node_id` | `str | null` | 否 | 成功後導向的 result node |
| `failure_result_node_id` | `str | null` | 否 | 失敗後導向的 result node |

## 8. SaveGame 最小結構

第一個切片至少需要可保存以下資訊：

- `quest_id`
- `current_node_id`
- `completed_node_ids`
- `completed_challenge_ids`
- `toolbox_state`
- `battery_state`
- `last_submission_summary`

## 9. 驗收重點

- sample YAML 可清楚對應本文件欄位
- `scene-city-alarm.yaml` 可展示新舊欄位並存
- Godot mapper 與 scene contract 可以直接消化新的劇情頁資料骨架

## 10. 後續延伸

- 若未來要加入結局劇情、分支敘事或音效控制，可在不破壞既有欄位的前提下往 `DialogueBlock` 擴充
- 若 Bridge 之後需要正式驗證，可把此文件轉為 JSON Schema 或 Python dataclass 驗證層

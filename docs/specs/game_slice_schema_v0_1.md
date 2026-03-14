# 遊戲第一個切片 Schema 規格（v0.1）

- 文件版本：0.1
- 更新日期：2026-03-14
- 適用範圍：第一個遊戲化 vertical slice
- 文件定位：定義第一個切片所需的最小資料格式，作為內容、Bridge 與存檔的共同資料語言

## 1. 目的

本文件用於將 `game_vertical_slice_plan.md`、`game_data_model_plan.md` 與 `game_system_boundary_plan.md` 中已確認的內容，壓成第一版可落地 schema。

本文件不是完整最終遊戲 schema，只覆蓋第一個切片真正會用到的部分。

## 2. 設計原則

- 優先支撐第一個可玩切片，不超前設計多章節需求
- 遊戲節點、劇情場景、挑戰群組、練習關狀態與存檔彼此分層
- 欄位名稱以穩定、可讀與可擴充為優先
- 範例使用 YAML，後續可再轉為 JSON / dataclass /正式驗證 schema

## 3. 參考樣板

本文件只保留欄位契約與設計邊界。

完整 YAML 樣板請直接參考：

- `docs/specs/examples/game_slice_v0_1/nodes-basic-io.yaml`
- `docs/specs/examples/game_slice_v0_1/quest-basic-io-repair.yaml`
- `docs/specs/examples/game_slice_v0_1/scene-*.yaml`
- `docs/specs/examples/game_slice_v0_1/challenge-*.yaml`
- `docs/specs/examples/game_slice_v0_1/toolbox-basic-io.yaml`
- `docs/specs/examples/game_slice_v0_1/battery-basic-io.yaml`
- `docs/specs/examples/game_slice_v0_1/savegame-basic-io.example.yaml`

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
| `portrait_id` | `str | null` | 否 | 角色立繪或頭像識別 |
| `expression` | `str | null` | 否 | 表情識別 |
| `emphasis` | `str | null` | 否 | 額外語氣標記，如 `normal` / `alert` / `success` |

#### 5.2.2 第一版刻意不先定死的欄位

以下欄位未來很可能需要，但第一版先不納入正式 schema：

- `voice_id`
- `bgm_cue`
- `sfx_cue`
- `camera_cue`
- `transition`
- `choices`
- `next_scene_id`

理由：

- 第一個 vertical slice 先驗證節點切換、對話閱讀與程式關卡進入流程
- 若太早把演出欄位全部定死，後續很容易為了假設中的呈現方式反覆改 schema
- 先保留文字、說話者、立繪與表情空間，已足夠支撐第一版對話框

## 6. ChallengeSpec

用途：

- 定義遊戲層可啟動的一組挑戰

### 6.1 欄位

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `challenge_id` | `str` | 是 | 挑戰群組唯一識別 |
| `challenge_type` | `str` | 是 | `demo` / `practice` |
| `title` | `str` | 是 | 群組名稱 |
| `level_ids` | `list[str]` | 是 | 對應現有 level 或後繼 challenge 項目 |
| `toolbox_policy_id` | `str | null` | 否 | 工具包規則識別 |
| `battery_policy_id` | `str | null` | 否 | 電池規則識別 |

## 7. PracticeRunState

用途：

- 定義固定 5 題練習關整組進度

### 7.1 欄位

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `practice_run_id` | `str` | 是 | 練習關執行識別 |
| `challenge_id` | `str` | 是 | 對應練習群組 |
| `question_index` | `int` | 是 | 目前進度位置 |
| `question_results` | `list[dict]` | 是 | 每題結果摘要 |
| `toolbox_used_flags` | `list[bool]` | 是 | 每題是否使用過工具包 |
| `battery_percent` | `int` | 是 | 當前累積能量 |
| `cooldown_until` | `str | null` | 否 | 冷卻截止時間 |
| `completed` | `bool` | 是 | 是否已跑完整組 |
| `passed` | `bool` | 是 | 是否整組通過 |

## 8. SaveGame

用途：

- 定義第一個切片最小可恢復存檔

### 8.1 欄位

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `save_version` | `str` | 是 | 存檔版本 |
| `current_node_id` | `str` | 是 | 玩家目前所在節點 |
| `unlocked_node_ids` | `list[str]` | 是 | 已解鎖節點 |
| `completed_node_ids` | `list[str]` | 是 | 已完成節點 |
| `completed_challenge_ids` | `list[str]` | 否 | 已完成 challenge group |
| `toolbox_state` | `dict` | 是 | 目前可用積木或工具包狀態 |
| `practice_run_states` | `list[PracticeRunState]` | 否 | 練習關整組狀態 |
| `story_flags` | `dict[str, bool]` | 否 | 劇情旗標 |

## 9. 切片固定識別

第一版切片目前固定使用下列識別：

- 節點
  - `map-entry`
  - `story-intro`
  - `demo-basic-io`
  - `practice-basic-io`
  - `result-basic-io`
  - `next-main-node`

- 場景
  - `scene-city-alarm`
  - `scene-practice-unlock`
  - `scene-result-success`
  - `scene-result-fail`

- 挑戰群組
  - `challenge-demo-basic-io`
  - `challenge-practice-basic-io`

- 任務
  - `quest-basic-io-repair`

## 10. 與既有系統的關係

- `ChallengeSpec.level_ids` 之後可映射到既有 `LevelSpec.level_id`
- `PracticeRunState` 與 `SaveGame` 是現有 progress 機制尚未承接的部分
- 後續實作時，可先用 YAML / dict 驗證 schema，再決定是否轉成 dataclass 或正式驗證 schema

## 11. 下一步

1. 依本文件產出第一版內容檔案草稿
2. 依本文件定義 Bridge request / response 的最小 payload
3. 依本文件改造現有 progress / save 流程
4. 視 UI 演出需求，再決定是否新增更完整的 dialogue schema

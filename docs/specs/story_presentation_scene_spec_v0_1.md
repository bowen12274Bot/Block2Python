# Story Presentation Scene Spec

- 版本：`v0.2`
- 日期：`2026-03-22`
- 狀態：草案
- 範圍：定義 Godot 劇情演出場景在第一版需要遵守的 UI 結構、view model 與 scene payload 形狀。

## 1. 目的

目前 `scene_view` 只足夠支撐文字式 scene panel，無法表達正式劇情演出需要的背景、角色槽與焦點狀態。

本規格定義：

- 劇情演出場景最小 UI 分層
- `scene_view` 應暴露給 Godot 的資料形狀
- `dialogue_blocks` 在保留既有欄位前提下的最小擴充方向

## 2. 場景結構

Godot 劇情頁第一版應至少包含以下區塊：

```text
StoryPresentationScreen
- BackgroundLayer
- CharacterLayer
  - LeftActorSlot
  - RightActorSlot
- DialogueLayer
  - Nameplate
  - BodyText
  - ContinueHint
- OverlayLayer
```

### 2.1 BackgroundLayer

責任：

- 顯示全畫面背景
- 保留後續加入漸層、特效或轉場的空間

第一版最低需求：

- 單張背景圖
- 背景未指定時使用預設背景或沿用上一段

### 2.2 CharacterLayer

責任：

- 承接左右角色圖
- 表達角色狀態變化

第一版最低需求：

- 左右兩個角色槽
- 每個角色槽可顯示以下狀態：
  - `hidden`
  - `dim`
  - `focus`
  - `silhouette`

### 2.3 DialogueLayer

責任：

- 顯示發話者名稱
- 顯示單段對話內容
- 顯示是否可繼續

第一版最低需求：

- 固定於畫面下方
- 半透明面板
- 發話者名牌
- 單段正文
- 繼續提示

## 3. Interaction Contract

### 3.1 點擊推進

- 玩家點擊時，若目前段落可前進，則進入下一段。
- 若已在最後一段，則 emit 完成事件。
- 第一版不強制加入打字機效果，因此不需要處理「先顯示全文 / 再前進」的雙階段互動。

### 3.2 焦點規則

- 若段落設定 `speaker_side = left`，預設左側角色進入 `focus`，右側角色進入 `dim`。
- 若段落設定 `speaker_side = right`，預設右側角色進入 `focus`，左側角色進入 `dim`。
- 若段落為旁白，可讓雙方維持 `dim`、`hidden` 或由段落明確指定。

## 4. View Model Shape

Godot 劇情頁應由 mapper 提供 `scene_view`，不得在 panel 中直接解析 raw `state.scene`。

第一版採相容輸出：保留舊版 `body`，同時新增正式劇情頁需要的 presentation 資料。

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

### 4.1 必要欄位

- `scene_id`
- `title`
- `current_index`
- `total_blocks`
- `can_advance`
- `background`
- `left_actor`
- `right_actor`
- `dialogue`
- `dialogue_blocks`
- `continue_hint_text`

### 4.2 過渡期相容欄位

- `mode_label`
- `node_label`
- `body`

這些欄位在 UI 改版前仍可供舊版文字型劇情頁使用。

## 5. Scene Payload Shape

資料來源為 `state.scene.dialogue_blocks`。

第一版採保留並擴充策略：
保留既有文字型劇情頁使用過的欄位，再補上正式劇情頁所需欄位。

### 5.1 既有欄位

- `speaker`
- `text`
- `portrait_id`
- `expression`
- `emphasis`

### 5.2 新增欄位

- `speaker_side`
- `background_id`
- `left_actor`
- `right_actor`

### 5.3 Actor Slot 最小結構

```yaml
left_actor:
  actor_id: "byte"
  pose_id: "default"
  expression_id: "alert"
  visual_state: "focus"
```

`right_actor` 結構相同。

第一版 `visual_state` 只支援：

- `hidden`
- `dim`
- `focus`
- `silhouette`

## 6. Mapper 責任

`game_flow_mapper.gd` 第一版至少需要負責：

- 由當前段落推導 `background`
- 由當前段落輸出 `left_actor` 與 `right_actor`
- 產出當前 `dialogue`
- 保留完整 `dialogue_blocks` 供後續 UI 或 debug 使用
- 在舊資料缺少新欄位時提供 fallback

## 7. 相容策略

- 舊內容仍可被 mapper 轉成基本可用的 presentation skeleton。
- 若同時存在新舊欄位，正式劇情頁以新欄位為主。
- `body` 在過渡期仍保留，供舊版文字型 scene panel 使用。

## 8. 非範圍

本規格第一版不處理：

- 分支選項
- 鏡頭動畫
- Live2D / 骨架動畫
- 配音與音效 cue
- 特殊事件演出腳本

## 9. 驗收條件

- 開場劇情、主地圖 story 節點與未來結局劇情可共用同一套 `scene_view` 結構。
- `scene-city-alarm.yaml` 可展示背景、左右角色與焦點切換。
- Godot UI 即使尚未完成正式改版，也能先拿到完整劇情頁資料骨架。
# 玩家 Toolbox 進度規格 v0.1

- 版本：`0.1`
- 日期：`2026-03-29`
- 狀態：Draft

## 1. 摘要

本文件定義玩家在五個階段遊戲流程中的 toolbox 積木解鎖規則。

toolbox 採用永久解鎖制：

- 玩家一旦到達更高階段，該階段對應的積木會永久保留。
- toolbox 可用積木由「玩家目前最高已解鎖 group 階段」決定。
- 此規則統一套用於 `demo`、`practice` 與 `review practice`。

本版規格不新增獨立的 toolbox save 欄位，而是直接從既有地圖 / group 狀態機推導玩家進度。

## 2. 玩家最高已解鎖階段

玩家最高已解鎖 toolbox 階段，依 group 狀態按以下優先順序判定：

1. 若存在 `current` group，該 group 視為玩家目前最高已解鎖階段。
2. 若不存在 `current` group，則取最高的 `completed` 或 `reviewing` group。
3. `available` group 不算已學會階段。
4. `locked` group 不算已解鎖。
5. 若以上條件皆不成立，回退到 `group-01`。

### 狀態語意

- `current`
  - 代表玩家目前主線正在推進的階段。
  - 算已解鎖。
- `completed`
  - 代表該 group 已完成。
  - 算已解鎖。
- `reviewing`
  - 代表該 group 已完成，且玩家目前正在回頭重玩 / 複習。
  - 算已解鎖。
- `available`
  - 代表該 group 已可進入，但不視為玩家已經學會該階段內容。
  - 不算 toolbox 解鎖來源。
- `locked`
  - 代表該 group 尚未解鎖。
  - 不算。

## 3. 階段對應積木

toolbox 進度對應以下 group policy。

### `group-01`

- `text_print`
- `b2p_input_text`

### `group-02`

- `group-01` 全部積木
- `b2p_to_int`
- `variables_set`
- `variables_get`
- `math_number`
- `math_arithmetic`

### `group-03`

- `group-02` 全部積木
- `logic_compare`
- `b2p_if`

### `group-04`

- `group-03` 全部積木
- `b2p_for_range`

### `group-05`

- `group-04` 全部積木
- `text`

## 4. 規則

- toolbox 解鎖是永久性的，不會倒退。
- 玩家回到舊 group 時，不會失去已解鎖的積木。
- `demo`、`practice`、`review practice` 都使用同一套「玩家最高已解鎖階段」規則。
- `variables_set` 解鎖時，`variables_get` 必須一併可用。
- `b2p_if_else` 不屬於目前任何正式解鎖階段，不能出現在 toolbox 中。

## 5. 真實來源

toolbox progression 的真實來源是既有 group 狀態模型。

實作時應直接依賴目前地圖渲染已使用的 group 狀態語意：

- `current`
- `completed`
- `reviewing`
- `available`
- `locked`

本版不新增獨立的 `highest_toolbox_stage` save 欄位。

## 6. 實作備註

- Python 邏輯層應提供一個共用 helper，用來解析玩家目前最高已解鎖 toolbox group。
- `DemoState.toolbox_block_ids` 與 `PracticeState.toolbox_block_ids` 都應使用同一個 helper。
- toolbox 渲染應使用「玩家目前最高階段」對應的 policy，而不是單純使用當前進入的 challenge group。
- 現有 `toolbox-group-01` 到 `toolbox-group-05` 仍是正式的 unlocked block ids 資料來源。

## 7. 預期情境

### 初始狀態

- 玩家實際只到 `group-01`。
- toolbox 顯示 `group-01` 積木。

### 玩家主線推進到 `group-02`

- `group-02` 成為 `current`。
- toolbox 在所有 demo / practice 中都顯示 `group-02` 積木。

### 玩家回看 `group-01`

- 即使回到舊的 `demo` 或 `practice`，toolbox 仍顯示目前最高已解鎖階段的積木。

### 玩家進入 review mode

- 已完成 group 可能變成 `reviewing`。
- toolbox progression 不會因此倒退。

### 玩家全破

- 即使沒有新的 `current` group，toolbox 仍應使用最高 `completed` group。
- 因此 toolbox 應維持在 `group-05`。

## 8. 本版不處理

- 每個 demo 自己額外的 allowlist
- 每題 level 級別的 toolbox 限制
- 背包 / inventory 類型的 toolbox 解鎖
- `if_else` 的正式開放計畫

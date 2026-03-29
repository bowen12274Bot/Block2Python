# Godot POC

這個目錄是 Block2Python 的 Godot 端原型專案。

它的角色不是完整遊戲本體，而是：
- 啟動並連接 Python bridge
- 接收 bridge 回傳的 `GameState`
- 在 Godot 端呈現 `map / scene / demo / practice` 幾個主要流程畫面
- 驗證 Godot UI、流程協調、後端狀態轉換是否能順利配合

## 專案入口

Godot 專案入口：
- `godot_poc/project.godot`

主流程場景：
- `godot_poc/scenes/game_flow_root.tscn`

主流程協調器：
- `godot_poc/scripts/flow/coordinator.gd`

## 目錄總覽

### `scenes/`
放 Godot 場景檔。

目前主要場景包含：
- `game_flow_root.tscn`：整個 POC 的主場景
- `quest_map_screen.tscn`：主地圖畫面
- `scene_flow_screen.tscn`：劇情畫面
- `demo_screen.tscn`：demo 畫面
- `practice_screen.tscn`：practice 畫面

### `scripts/`
放 Godot 端執行邏輯。

目前主要可分成幾類：
- `bridge/`：和 Python bridge 溝通
- `entry/`：入口頁與角色建立
- `flow/`：高層流程協調
- `game_flow/`：scene / demo / practice / feedback
- `map/`：quest map 模組
- `shared/`：跨模組共用 helper

更細的腳本分層請看：
- `godot_poc/scripts/README.md`

### `art/`
放 Godot 端使用的 UI、美術與故事相關素材。

### `.godot/`
Godot 編輯器與匯入快取。

這個目錄不是功能程式碼的一部分，但在大量 rename / move script 後，快取有時會殘留舊路徑資訊。

## 目前專案意圖

這個 POC 目前重點在驗證以下幾件事：
- Python bridge 是否能穩定推送 `GameState`
- Godot 是否能依照 state 正確切換頁面與流程
- map、scene、demo、practice 幾個核心畫面是否能用一致的資料流驅動
- UI 層、流程層、state mapping 層是否能維持清楚分工
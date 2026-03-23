# Godot POC

這個目錄放的是目前的 Godot 主 client prototype。

## 目前主線

Godot 專案入口由 `godot_poc/project.godot` 指向：

- `scenes/game_flow_root.tscn`
- `scripts/flow/game_flow_coordinator.gd`

這是目前唯一保留的主流程。它負責：

- 啟動 Python stdio bridge
- 接收 bridge 回傳的 `GameState`
- 在 map / scene / challenge 三個畫面間切換
- 將 state 轉成 Godot 可直接 render 的 view model

## scripts 分區

如果先不看 mapper / presenter 這些技術名詞，可以把 `scripts/` 簡單理解成四塊：

- `scripts/bridge/`
  - 負責跟 Python backend 溝通。
  - `python_bridge_client.gd` 會啟動 Python bridge process，透過 stdin/stdout 傳 JSON。
  - `bridge_state_store.gd` 會暫存最後一份成功的 bridge state。
- `scripts/flow/`
  - 負責主流程控制。
  - `game_flow_coordinator.gd` 會接 bridge 回應，決定現在要留在 map、切到 scene，還是切到 challenge。
- `scripts/map/`
  - 負責主地圖那一頁。
  - `quest_map_screen.gd` / `quest_map_panel.gd` 是地圖畫面本身。
  - 其他檔案則負責把 bridge 的 route state 轉成地圖可顯示的資料與說明文字。
- `scripts/game_flow/`
  - 負責劇情頁與挑戰頁。
  - `scene_flow_screen.gd` / `scene_panel.gd` 是劇情頁。
  - `challenge_screen.gd` / `challenge_panel.gd` / `feedback_panel.gd` 是挑戰頁。
  - 其他檔案則負責把 bridge state 轉成 scene / challenge 可顯示的資料與 feedback 文字。

如果用流程順序理解，可以想成：

1. `bridge/` 先把資料從 Python 拿回來
2. `flow/` 決定現在該顯示哪一頁
3. `map/` 負責主地圖頁
4. `game_flow/` 負責劇情頁和挑戰頁

## 畫面分工

- `scenes/quest_map_screen.tscn`
  - 主地圖畫面。
- `scenes/scene_flow_screen.tscn`
  - 劇情節點畫面。
- `scenes/challenge_screen.tscn`
  - 挑戰節點畫面。

這三個 screen 由 `game_flow_root.tscn` 組合起來。

## 已移除的舊 prototype

以下舊原型已不再作為主線保留：

- `scenes/main.tscn`
- `scripts/main_controller.gd`
- `scenes/quest_map.tscn`
- `scripts/quest_map_controller.gd`

## 使用方式

1. 用 Godot 開啟 `godot_poc/project.godot`
2. 執行專案
3. 按 `Start Bridge`
4. 按 `Reset` 取得目前 quest state

## 備註

- 這裡仍是 POC，不代表最終正式 UI 結構。
- `.godot/` 是 Godot editor cache，不是需要整理的程式碼主體。

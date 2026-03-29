# 腳本結構說明

這個目錄存放 Block2Python POC 在 Godot 端的主要腳本。

## 目錄分工

- `bridge/`
  - 放 bridge client、bridge state store、視窗對位相關 helper。
  - 負責和外部 Python bridge 溝通，並保存最新的 GameState。

- `entry/`
  - 放入口頁與角色建立相關腳本。

- `flow/`
  - 放高層流程協調邏輯。
  - `coordinator.gd`：主流程協調器，負責 bridge 事件、頁面切換、各畫面更新。
  - `page_router.gd`：根據目前 state 決定應顯示哪個頁面。
  - `screen_presenter.gd`：把 mapper 產出的 view model 套到各個 screen。
  - `toolbox/`：toolbox 子系統，目前主要是 toolbox controller。

- `game_flow/`
  - 放 scene、demo、practice、feedback 這條遊戲流程的 UI 腳本。
  - `mappers/`：把 GameState 轉成 game flow 用的 view model。
  - `presentation/`：只負責呈現規則或 presenter 邏輯，不直接碰 scene tree。
  - `ui/`：直接綁定 Godot control、panel、screen 的腳本。
  - `ui/scene_panel/`：`scene_panel.gd` 拆出的 helper，集中處理 preview、style、runtime、asset resolve、actor render 等細節。

- `map/`
  - 放 quest map 模組。
  - `catalog/`：map 的靜態 metadata。
  - `mappers/`：把 state 轉成 map view。
  - `presentation/`：map 的顯示規則與 presenter。
  - `ui/`：map screen 與 map render 相關腳本。

- `shared/`
  - 放跨模組共用的 helper。

## 分層原則

- `flow/` 負責 bridge 驅動下的頁面流程與高層協調。
- `game_flow/mappers/` 與 `map/mappers/` 負責把 GameState 轉成 view data。
- 各模組的 `presentation/` 只放呈現規則，不處理 scene node 綁定。
- 各模組的 `ui/` 可以直接操作 scene tree、control 與 signal。
- `catalog/` 只放靜態資料，不放 runtime 流程邏輯。

## 目前整理方向

- bridge 與頁面切換的協調集中在 `flow/`。
- feature 專屬 UI 盡量留在 `game_flow/` 與 `map/`。
- 當某支腳本同時混入 scene wiring、view mapping、靜態 metadata 時，應先拆責任再繼續加功能。
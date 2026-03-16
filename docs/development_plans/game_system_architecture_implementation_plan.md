# 遊戲系統架構實作清單

- 版本：0.2
- 日期：2026-03-14
- 狀態：可執行草案
- 對應文件：`docs/development_plans/game_system_architecture_plan.md`

## 1. 目的

本文件把架構提案轉成可直接開工的實作清單。

它要回答：

1. 先重構哪些骨架。
2. 哪些模組要為 Godot 和中間連接層預留位置。
3. 每個階段的完成條件與測試是什麼。

## 2. 目前狀態摘要

目前 repo 已經有可運作的 Python prototype：

- `src/block2python/app/core.py`
  - challenge submit / analysis / judge facade
- `src/block2python/app/game_session.py`
  - 最小 quest / node / challenge orchestration
- `src/block2python/game_content/`
  - game content loader / models / runtime assembly
- `src/block2python/app/progress.py`
  - 目前只有 level cleared / block passed
- `src/block2python/ui/window.py`
  - UI 仍直接操作 `AppCore`

目前缺口：

- 還沒有正式 `GameState` / `PlayerAction`
- 還沒有 integration dispatcher / bridge
- 還沒有可承接 `SaveGame` 的資料層
- 還沒有顯式納入 Godot 的骨架位置
- 測試仍有 tmp 權限問題

## 3. 開發原則

- 先做責任邊界收斂，再做 contract。
- 骨架重構的目的，是讓 Godot 和 integration layer 能自然接進來。
- 不重寫 `judge/`、`analysis/`、`levels_loader.py` 的核心行為，除非新邊界明確要求。
- 不在骨架重構階段加入新玩法。
- 每個 phase 都要有自動測試，不接受只靠手動 demo。

## 4. 目標骨架

建議把 Python 端整理成以下結構：

```text
src/block2python/
  challenge/
  content/
  game/
  integration/
  clients/
```

責任如下：

- `challenge/`
  - level submit
  - judge / analysis
  - challenge-level progress

- `content/`
  - levels loader
  - game content loader
  - content models
  - content assembly

- `game/`
  - `GameSession`
  - quest / node runtime
  - savegame
  - game rule orchestration

- `integration/`
  - `GameState` / `PlayerAction`
  - serializers
  - dispatcher
  - stdio bridge
  - Godot adapter 預留位置

- `clients/`
  - PySide6 UI
  - CLI demo
  - smoke / local tools entrypoint

## 5. integration 層的明確位置

這一層必須在骨架階段就保留，不能等到 Godot 開始做才補。

建議結構：

```text
src/block2python/integration/
  contracts/
  service/
  bridge_stdio/
  godot_adapter/
```

責任如下：

- `integration/contracts/`
  - `GameState`
  - `PlayerAction`
  - nested payload models
  - serializer / validation

- `integration/service/`
  - `dispatch(PlayerAction) -> GameState`
  - application-facing entrypoint

- `integration/bridge_stdio/`
  - subprocess / stdin / stdout JSON bridge

- `integration/godot_adapter/`
  - 給 Godot 專案接入時使用的 adapter 預留位置
  - 這一階段可以先只有 package 和 README，不必先寫功能

## 6. 建議檔案落點

骨架重構後建議新增：

- `src/block2python/challenge/__init__.py`
- `src/block2python/content/__init__.py`
- `src/block2python/game/__init__.py`
- `src/block2python/integration/__init__.py`
- `src/block2python/clients/__init__.py`

integration contract 階段再新增：

- `src/block2python/integration/contracts/__init__.py`
- `src/block2python/integration/contracts/models.py`
- `src/block2python/integration/contracts/serialize.py`
- `src/block2python/integration/contracts/errors.py`

bridge MVP 階段再新增：

- `src/block2python/integration/service/__init__.py`
- `src/block2python/integration/service/dispatcher.py`
- `src/block2python/integration/bridge_stdio/__init__.py`
- `src/block2python/integration/bridge_stdio/server.py`
- `src/block2python/integration/godot_adapter/__init__.py`

clients 過渡階段可搬遷：

- `src/block2python/clients/pyside6/`
- `src/block2python/clients/cli/`

測試對應：

- `tests/test_integration_contract_models.py`
- `tests/test_integration_contract_serialize.py`
- `tests/test_game_session_contract.py`
- `tests/test_savegame_progress.py`
- `tests/test_integration_dispatcher.py`
- `tests/test_bridge_stdio.py`

## 7. 執行順序

### Phase -1. 專案骨架重構

目標：先把責任邊界切開，讓後續 contract、save、bridge、Godot adapter 都長在正確位置。

本階段只做結構收斂，不做玩法擴張。

工作項目：

1. 建立 `challenge/`、`content/`、`game/`、`integration/`、`clients/` package。
2. 決定每個現有模組應該落在哪個邊界。
3. 將 `AppCore` 定位到 challenge domain。
4. 將 `GameSession` 定位到 game domain。
5. 將 `game_content/` 定位到 content domain。
6. 將 PySide6 / CLI demo 歸到 clients domain。
7. 預留 integration 層與 Godot adapter 位置。
8. 保留 forwarding shim，避免一次改爆 import。

建議改動：

- 新增 `src/block2python/challenge/`
- 新增 `src/block2python/content/`
- 新增 `src/block2python/game/`
- 新增 `src/block2python/integration/`
- 新增 `src/block2python/clients/`
- 視需要保留舊模組作為 forwarding shim

這一階段不該做的事：

- 不重寫 judge 行為
- 不改 level schema
- 不實作 Godot-specific 邏輯
- 不加入新玩法

完成條件：

- 看目錄就能辨識 challenge / content / game / integration / clients 的責任。
- `integration/` 已存在，且可自然承接未來 Godot。
- `GameSession` 不再像 `AppCore` 的附屬品。
- `ui/` 類模組被視為 client adapter，不是遊戲主流程層。

測試：

- import smoke test
- 現有 session / app / content 測試回歸
- CLI / demo 啟動 smoke test

### Phase 0. 測試基線整理

目標：先讓 repo 的測試可以穩定跑完。

工作項目：

1. 修正 `pytest` tmp 目錄使用策略。
2. 確認 `.tmp/` 內 pytest cache / htmlcov 可正常建立。
3. 補最小開發說明。

建議改動：

- `pyproject.toml`
- `tests/conftest.py`
- `tests/README.md`

完成條件：

- `pytest` 在目前 workspace 可穩定執行。
- 不再出現 `tmp_path` 相關權限錯誤。

### Phase 1. Integration Contract Layer

目標：建立 Godot 與其他前端都能依賴的正式 contract。

工作項目：

1. 新增 `GameState` dataclass。
2. 新增 `PlayerAction` dataclass。
3. 定義 nested payload：
   - `SceneState`
   - `ChallengeState`
   - `ProgressState`
   - `AvailableActions`
4. 加入 serializer。
5. 提供 example payload。

建議欄位：

- `GameState`
  - `mode`
  - `quest_id`
  - `node_id`
  - `node_title`
  - `scene`
  - `challenge`
  - `progress`
  - `available_actions`
  - `errors`

- `PlayerAction`
  - `action_type`
  - `payload`

建議改動：

- 新增 `src/block2python/integration/contracts/`
- `src/block2python/app/game_session.py` 或搬遷後的 `game/` session module
- `src/block2python/app/game_session_demo.py` 或搬遷後的 `clients/cli/`

完成條件：

- `GameSession` 可以輸出完整 `GameState`。
- terminal demo 改由 `GameState` render。
- Godot 未來只需要依賴 integration contract，不依賴內部模組。

測試：

- contract model 單元測試
- serializer 單元測試
- `GameSession -> GameState` 流程測試
- example payload snapshot test

### Phase 2. Session / App 邊界收斂

目標：讓 `GameSession` 成為遊戲主入口，`AppCore` 固定停留在 challenge subsystem。

工作項目：

1. 在 `GameSession` 內統一處理：
   - `advance`
   - `submit_level`
   - challenge clear 後 node 推進
   - scene 已讀狀態
2. 明文化 `GameSession` 可接受的 action 集合。
3. 將 PySide6 端從直接操作 `AppCore`，改成走 `GameSession` 或 integration dispatcher。
4. 將 `AppCore` 對外責任限制在 challenge 子系統。

建議改動：

- `src/block2python/app/game_session.py`
- `src/block2python/app/core.py`
- `src/block2python/ui/window.py`
- `src/block2python/integration/service/dispatcher.py`

完成條件：

- UI 不再自己拼接 challenge 流程。
- `GameSession` 可覆蓋完整 vertical slice 流程。
- `AppCore` 不新增 quest / node / scene 概念。

測試：

- quest end-to-end test
- scene/challenge 交替流程 test
- challenge clear 後狀態轉換 test

### Phase 3. Save / Progress 升級

目標：從目前 level-only progress 升級成可承接遊戲流程的 save model。

工作項目：

1. 定義 `SaveGame` dataclass。
2. 新增 node / challenge 層級狀態。
3. 保留與舊 progress 的 migration 策略。
4. 規劃 `PracticeRunState` 與 `BatteryState` 的最小骨架。
5. 讓 `GameSession` 能從 save 恢復狀態。

建議改動：

- `src/block2python/app/progress.py`
- 新增 `src/block2python/app/savegame.py`
- `src/block2python/app/runtime.py`
- `src/block2python/app/game_session.py`

完成條件：

- save file 不只記錄 cleared levels。
- 可以重啟後回到正確 quest / node。
- 預留未來擴充 `PracticeRunState` 的欄位位置。

測試：

- save/load round-trip test
- 舊 progress 載入 test
- session resume test

### Phase 4. Bridge MVP

目標：建立 Godot 可呼叫的 Python 邊界。

工作項目：

1. 實作 `dispatch(PlayerAction) -> GameState`。
2. 初版 bridge 採 stdio JSON。
3. 定義 request / response envelope。
4. 加入錯誤回應格式。
5. 補 smoke script。

建議 request：

```json
{
  "action": {
    "action_type": "advance",
    "payload": {}
  }
}
```

建議 response：

```json
{
  "ok": true,
  "state": {
    "mode": "scene"
  },
  "error": null
}
```

建議改動：

- `src/block2python/integration/service/`
- `src/block2python/integration/bridge_stdio/`
- `src/block2python/integration/godot_adapter/`
- `tests/test_integration_dispatcher.py`
- `tests/test_bridge_stdio.py`
- `tools/run_bridge_smoke.ps1`

完成條件：

- 外部 process 可以送 action 並取得新 state。
- 錯誤 action 有穩定格式回應。
- 不需要 PySide6 或 Godot 也能單獨驗證 bridge。

### Phase 5. Clients 過渡整合

目標：讓現有 PySide6 與 CLI demo 變成 contract consumer，而不是主流程控制者。

工作項目：

1. UI 改由 `GameSession` / integration contract 驅動顯示。
2. 保留 Blockly 驗證與提交功能。
3. `Reset Progress` 改成對 save/progress abstraction 操作。
4. 移除 UI 對 `AppCore` 內部細節的依賴。

建議改動：

- `src/block2python/ui/window.py`
- `src/block2python/ui/main.py`
- 或搬遷到 `src/block2python/clients/pyside6/`

完成條件：

- UI 可顯示 scene 與 challenge 的 `GameState`。
- UI 不直接決定 quest/node 流程。

### Phase 6. Godot 接入準備

目標：讓 Godot 端只依賴 integration 層就能開始工作。

工作項目：

1. 確認 `GameState` 欄位足夠 render 第一條 quest。
2. 補 contract examples 給 Godot 使用。
3. 定義 Godot 端只允許的 `PlayerAction` 集合。

完成條件：

- Godot 端只看 contract 文件與 payload examples 就能開始實作。

## 8. Ticket 拆分

### T-1-1 建立新 package 骨架與 forwarding shim

- 類型：refactor
- 依賴：無
- 驗收：
  - 新 package 可 import
  - 舊 import 暫時不中斷

### T-1-2 將 `AppCore` / `GameSession` / `game_content` / UI entry 收斂到新邊界

- 類型：refactor
- 依賴：T-1-1
- 驗收：
  - challenge / content / game / integration / clients 邊界可讀
  - 現有核心測試仍通過

### T0-1 修正 pytest tmp 權限問題

- 類型：infra
- 依賴：T-1-2 或確認不需要測試結構搬遷
- 驗收：
  - `pytest` 可跑完
  - `tmp_path` fixture 正常

### T1-1 新增 integration contract 模組與 dataclass

- 類型：backend
- 依賴：T-1-2, T0-1
- 驗收：
  - 有 `GameState` / `PlayerAction`
  - 有 serializer test

### T1-2 `GameSession` 輸出 `GameState`

- 類型：backend
- 依賴：T1-1
- 驗收：
  - session test 全數走 contract
  - demo 不再直接讀內部 state 欄位

### T2-1 明確收斂 `GameSession` / `AppCore` 邊界

- 類型：refactor
- 依賴：T1-2
- 驗收：
  - UI 或 demo 不需要自己組 challenge 流程

### T3-1 設計 `SaveGame` 與 migration

- 類型：backend
- 依賴：T2-1
- 驗收：
  - save/load round-trip 通過

### T4-1 實作 integration dispatcher 與 bridge

- 類型：integration
- 依賴：T1-2
- 驗收：
  - `dispatch(action)` 可回傳 JSON state

### T5-1 將 PySide6 轉成 contract consumer

- 類型：frontend integration
- 依賴：T2-1, T3-1
- 驗收：
  - UI 不直接操作 `AppCore` 主流程

## 9. 現在不做的事

- Godot 正式場景與美術資源
- 多章節 quest 擴充
- battery / toolbox 完整玩法
- 劇情分支 DSL
- judge / analysis 子系統重寫

## 10. 第一輪建議實作包

第一輪只做以下五張票：

1. `T-1-1` 建立 package 骨架與 shim
2. `T-1-2` 收斂 challenge / content / game / integration / clients 邊界
3. `T0-1` 修正測試基線
4. `T1-1` 新增 integration contract models
5. `T1-2` 讓 `GameSession` 輸出 `GameState`

這一輪完成後，repo 會得到：

- 可接 Godot 的專案骨架
- 穩定的 Python integration contract
- 可被 Godot 或 PySide6 消費的 `GameState`
- 較乾淨的邏輯層邊界

## 11. 建議下一步

實作順序建議如下：

1. 先做 package 骨架重構，但只重構邊界，不重寫邏輯。
2. 再解 `pytest` tmp 權限問題。
3. 接著做 integration contract 模組。
4. 改寫 demo 成 contract-driven。
5. 再處理 savegame 與 bridge。

如果現在要正式開始實作，第一張最合理的票是：

- 建立 challenge / content / game / integration / clients 新 package 骨架，並保留舊 import shim。

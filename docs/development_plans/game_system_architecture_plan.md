# 遊戲系統架構與落地計畫

- 版本：0.1
- 日期：2026-03-14
- 狀態：提案中
- 目的：正式定義 Block2Python 遊戲化版本的系統架構，並提供從目前 Python prototype 演進到 Godot 呈現層的落地計畫。

## 1. 決策摘要

本專案正式採用以下三層架構：

```text
Python Logic Layer
(遊戲規則 / 關卡流程 / 判定 / 狀態)
        |
        | GameState
        v
Integration Layer
(狀態交換 / 指令轉換 / 同步 / 錯誤處理)
        |
        v
Godot Game Layer
(UI / 場景 / 動畫 / 玩家互動)
```

核心原則：

- Python 是遊戲邏輯的唯一真實來源（Single Source of Truth）。
- Godot 負責呈現與互動，不直接決定遊戲規則與進度。 
- Python 與 Godot 之間只透過標準化資料契約交換狀態與操作。
- PySide6 保留為開發期驗證工具，不作為長期主遊戲前端。

## 2. 為什麼現在要定案

目前 repo 已經不再只是 Blockly 練習器，而是已具備以下遊戲骨架：

- `assets/levels/`：挑戰題目與 judge 設定。
- `assets/game_content/`：quest / node / scene / challenge / toolbox / battery 內容。
- `src/block2python/game_content/`：內容 loader、模型、assembly、runtime。
- `src/block2python/app/game_session.py`：最小主流程 orchestration。
- `src/block2python/app/game_session_demo.py`：終端版 end-to-end demo。

這代表現在已經到了必須明確切分「邏輯層」與「呈現層」責任的時間點，避免後續把流程控制綁死在臨時 UI 或 Godot 場景腳本中。

## 3. 三層架構定義

### 3.1 Python Logic Layer

負責：

- quest / node / scene / challenge 的流程控制
- 關卡題目與內容載入
- judge / analysis / wasm execution
- 遊戲規則、條件判定、進度更新
- save/progress 的真實狀態管理
- 對外輸出標準化 `GameState`

不負責：

- 正式遊戲畫面
- 場景動畫與特效
- 長期 UI 排版與互動演出

目前在 repo 中的對應：

- `src/block2python/app/core.py`
- `src/block2python/app/game_session.py`
- `src/block2python/game_content/loader.py`
- `src/block2python/game_content/runtime.py`
- `src/block2python/app/levels_loader.py`
- `src/block2python/judge/`
- `src/block2python/analysis/`

### 3.2 Godot Game Layer

負責：

- 地圖、場景、角色、對話呈現
- UI、動畫、音效、視覺回饋
- 玩家輸入收集
- 根據 `GameState` 更新畫面
- 將玩家操作轉換為 `PlayerAction`

不負責：

- 關卡規則判定
- 遊戲進度決策
- challenge 完成與否的最終裁定
- 任意修改真實遊戲狀態

Godot 的定位應視為：

- 正式遊戲前端
- Python 邏輯層的 consumer
- `GameState` 的 renderer

### 3.3 Integration Layer

負責：

- Godot 呼叫 Python 邏輯入口
- Python 狀態序列化與回傳
- 玩家操作轉為 Python 可處理的 action
- 錯誤處理、同步與診斷資訊

主要交換契約：

- `GameState`：Python -> Godot
- `PlayerAction`：Godot -> Python

這一層不應承擔真正遊戲規則，只應承擔跨技術邊界的轉換責任。

## 4. 專案內部責任切分

為了讓三層架構在目前 repo 中可落地，Python 邏輯層內部再切成四個子層：

### 4.1 Content Layer

負責載入與組裝靜態內容：

- `levels_loader.py`
- `game_content/loader.py`
- `game_content/models.py`
- `assets/levels/`
- `assets/game_content/`

### 4.2 Runtime Layer

負責內容導航與流程狀態：

- `game_content/runtime.py`
- `app/game_session.py`

職責：

- 決定目前 quest / node / scene / challenge
- 決定節點推進
- 對外提供可序列化的當前狀態

### 4.3 Challenge Layer

負責單個 level/challenge 的提交與判定：

- `app/core.py`
- `judge/`
- `analysis/`

職責：

- submission
- analysis
- judge
- clear state

### 4.4 Integration Contract Layer

未來新增，負責：

- `GameState` dataclass / schema
- `PlayerAction` dataclass / schema
- Python <-> Godot bridge adapter

## 5. 主要入口決策

### 5.1 Python 對外主入口

未來對 Godot 的主要入口應是：

- `GameSession`

原因：

- `GameSession` 已是目前 quest/node/challenge 的主流程控制器。
- `AppCore` 應持續專注在 challenge 提交與 judge 子系統，不應膨脹為整個遊戲總控。
- Godot 若直接操作 `AppCore`、loader、judge，會讓邊界混亂。

### 5.2 AppCore 的定位

`AppCore` 的正式定位：

- challenge subsystem
- level submit / judge / analyzer facade

而不是：

- Godot 的總入口
- 全遊戲狀態控制器

### 5.3 PySide6 的定位

PySide6 現階段定位：

- Blockly / challenge 驗證 UI
- 開發期 smoke / prototype 工具
- 不再作為長期正式遊戲 UI 的中心

## 6. 資料交換契約草案

### 6.1 Python -> Godot: GameState

`GameState` 至少應包含：

- `mode`
  - `scene`
  - `challenge`
  - `complete`
- `quest_id`
- `node_id`
- `node_title`
- `scene`
  - `scene_id`
  - `title`
  - `dialogue_blocks`
- `challenge`
  - `challenge_id`
  - `challenge_type`
  - `current_level_id`
  - `current_level_title`
- `progress`
  - `completed_node_ids`
  - `cleared_level_ids`
- `available_actions`
  - `advance`
  - `submit`

### 6.2 Godot -> Python: PlayerAction

`PlayerAction` 至少應包含：

- `action_type`
  - `advance`
  - `submit_level`
  - `restart_quest`
- `payload`
  - `python_code`
  - `block_json`
  - 其他 action 參數

### 6.3 設計原則

- 合約應明確命名，不使用任意 ad-hoc dict。
- 即使內部暫時用 dict，也應有清楚 schema 與 dataclass 對應。
- Godot 僅依賴 contract，不依賴 Python 內部實作細節。

## 7. 目前位置評估

截至目前，已完成：

- 挑戰題目載入
- 遊戲內容載入
- game content 與 levels 的 assembly
- 最小 runtime 導航
- `GameSession` 主流程控制
- 終端 demo 驗證入口

尚未完成：

- 正式 `GameState` / `PlayerAction` 契約定義
- Godot bridge
- save/progress 與 game-level state 整合
- Godot 呈現層接入
- PySide6 與 `GameSession` 的完整過渡整合

## 8. 落地開發計畫

### Phase 1. Contract 定義

目標：先定義 Integration Layer 的穩定契約。

工作項目：

1. 新增 `GameState` 與 `PlayerAction` 模型。
2. 定義可序列化 schema 與欄位約束。
3. 讓 `GameSession` 能輸出標準化 `GameState`。
4. 為 contract 補齊單元測試與 example payload。

完成條件：

- Python 端可以在不依賴 Godot 的情況下產生完整 `GameState`。
- 終端 demo 改為透過 `GameState` 驅動輸出，而不是直接讀 session 細節。

### Phase 2. Python Game Application Layer 穩定化

目標：把目前 prototype orchestration 收斂成正式應用層。

工作項目：

1. 明確整理 `GameSession` 與 `AppCore` 邊界。
2. 擴充 progress/save 模型，加入 node/challenge 層狀態。
3. 將 challenge 完成與 node 推進規則明文化。
4. 補齊 end-to-end 測試。

完成條件：

- quest 流程、challenge clear、node 推進可由自動測試完整覆蓋。
- 不需要 UI 也能穩定重播一條完整 vertical slice。

### Phase 3. Bridge MVP

目標：建立 Godot 與 Python 的最小橋接。

工作項目：

1. 選定 bridge 形式。
   - 初期建議：本機 subprocess + JSON stdin/stdout
   - 後續可視需要評估 socket / local API
2. 定義 Python bridge service entrypoint。
3. 實作 `dispatch(PlayerAction) -> GameState`。
4. 補齊 bridge smoke tests。

完成條件：

- Godot 可向 Python 發送一個 action 並收到新的 `GameState`。
- 不需要完整美術資源也能完成流程驗證。

### Phase 4. Godot Vertical Slice

目標：讓 Godot 成為正式遊戲前端。

工作項目：

1. 以 `GameState` 驅動 scene UI。
2. 以 `PlayerAction` 驅動流程互動。
3. 完成第一條 quest 的 playable slice。
4. 以 placeholder 視覺資源驗證整體流暢性。

完成條件：

- 玩家可在 Godot 中完成一條 quest。
- Python 仍是唯一邏輯來源。

### Phase 5. PySide6 過渡收斂

目標：讓 PySide6 從核心前端退回開發輔助工具。

工作項目：

1. 保留 Blockly/challenge 驗證用途。
2. 移除不再需要的遊戲主流程責任。
3. 整理工具腳本與開發說明。

完成條件：

- Godot 成為正式遊戲 UI。
- PySide6 成為開發或內容驗證工具，而非產品主入口。

## 9. 現在應該做什麼

在這份架構定案後，下一個最合理的實作順序是：

1. 定義 `GameState` / `PlayerAction` 契約。
2. 讓 `GameSession` 輸出契約化狀態。
3. 擴充 progress/save 模型到 node/challenge 層。
4. 做最小 Python bridge MVP。

不建議現在優先做的事：

- Godot 美術與完整 UI 細節
- battery / toolbox 全量數值系統
- 複雜劇情分支 DSL
- 多章節內容擴充
- 提前重寫既有 judge / analysis 子系統

## 10. 結論

本專案後續正式採用：

- Python 邏輯核心
- Godot 呈現層
- Integration Layer 橋接層

三層架構。

短期目標不是立即重寫所有 UI，而是先讓 Python 邏輯層輸出穩定的 `GameState`，再以 bridge 接上 Godot。這樣可以保留目前已完成的 loader / runtime / session 成果，同時避免未來 Godot 專案與 Python 規則層耦合失控。

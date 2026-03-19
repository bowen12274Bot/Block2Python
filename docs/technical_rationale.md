# 技術架構說明

- 版本：1.0
- 更新日期：2026-03-14
- 範圍：目前以 Python 為核心的遊戲系統架構說明

## 1. 決策摘要

Block2Python 現在已不再只是以 PySide6 包住 level submit 的 demo shell，而是逐步轉向「Python 邏輯層 + 未來 Godot 呈現層」的遊戲化架構。

目前的技術方向是：

- Python 仍是遊戲規則的 source of truth。
- `GameSession` 是預定的遊戲流程主入口。
- `AppCore` 維持 challenge 子系統，專注在 level submit 與 judge。
- 內容載入與流程控制已開始分層。
- 外部前端應透過 `integration/` 接入，而不是直接 import Python 內部模組。

## 2. 為什麼要先重構骨架

舊結構把多種責任混在一起：

- app 啟動與遊戲流程
- challenge submit 與 judge 組裝
- 內容載入
- PySide6 專屬 UI 行為

這種結構可以支撐 prototype，但不足以穩定承接後續工作，例如：

- 正式的 `GameState` / `PlayerAction` 契約
- savegame 擴充
- bridge adapter
- Godot 接入

因此，先重構骨架的目的是在功能繼續增加前，把責任邊界明確切開。

## 3. 目前分層

目前專案的核心骨架集中在五個 package：

- `challenge`
- `content`
- `game`
- `integration`
- `clients`

### 3.1 `challenge`

原因：
- 單題執行與 judge 是一個子系統，不是整個遊戲本體。
- `AppCore` 現在的責任天然符合這個定位。

這層應包含：
- submit flow
- judge 選擇與執行
- challenge 級 progress
- level clear / block pass 狀態

這層不應包含：
- quest orchestration
- scene flow
- 全遊戲 savegame
- 前端交換契約

### 3.2 `content`

原因：
- level 規格與遊戲內容本質上都屬於內容領域。
- 它們不應藏在 app bootstrapping 或前端實作裡。

這層應包含：
- level loading
- game content loading
- content models
- content/runtime assembly helpers

### 3.3 `game`

原因：
- 專案需要一個明確的遊戲狀態擁有者。
- `GameSession` 已經是最接近這個角色的模組。

這層應包含：
- session state
- 遊戲主流程控制
- 未來 savegame state
- 不屬於單題 challenge 的遊戲規則

### 3.4 `integration`

原因：
- Godot 或其他前端需要穩定邊界。
- 若沒有獨立 integration layer，前端就會直接依賴 Python 內部實作。

這層應包含：
- `GameState`
- `PlayerAction`
- serialization
- dispatch
- process bridge adapters
- Godot 專用薄 adapter

這層不應包含：
- 遊戲規則本身
- judge 內部細節
- 內容編輯邏輯

### 3.5 `clients`

原因：
- PySide6 與 CLI 是系統 consumer，不是系統本身。
- 把它們明確標為 clients，可以避免工具型 UI 反客為主，變成架構主邊界。

## 4. 依賴規則

目前預期的依賴方向如下：

```text
clients -> integration -> game
                      -> challenge
                      -> content

game -> challenge
game -> content

challenge -> judge / analysis / contracts
content -> contracts
```

規則如下：

- `clients` 長期不應直接 orchestrate `AppCore`。
- `integration` 是外部前端應依賴的唯一正式邊界。
- `game` 可以依賴 `challenge` 與 `content`，但應維持整體遊戲流程的控制權。
- `challenge` 不應擴張成 quest/node/scene 導演層。

## 5. 為什麼 Python 仍是 source of truth

Python 目前仍應作為 source of truth，原因是現有邏輯已經在 Python 端具備基礎能力：

- level loading
- analysis
- judge execution
- challenge submit flow
- quest/node/challenge progression

如果現在把規則搬進 Godot，會立刻帶來重複實作與迭代變慢的問題。維持 Python-first 的邏輯層可以得到：

- 更快的規則調整速度
- 較好的測試性
- 更清楚的前後端邊界
- 更薄的 Godot client

## 6. 為什麼 Godot 只能依賴 `integration`

Godot 的角色應是呈現層，不是規則引擎。

如果 Godot 直接 import Python 內部模組，會出現幾個問題：

- Python 內部重構會直接變成 Godot breaking change
- 前端會耦合到 backend implementation details
- 入口會變多，例如 `AppCore`、loader、runtime object、session object
- 測試邊界會變模糊

讓 Godot 只依賴 `integration/`，可以把資料交換強制收斂成一種正式模型：

- Python 回傳 `GameState`
- frontend 傳入 `PlayerAction`

## 7. 為什麼 PySide6 不再是長期邊界

PySide6 仍然有價值，但定位已經改變。

它目前的價值是：
- 開發驗證
- smoke testing
- 內部 demo client
- 內容檢查工具

它不應繼續作為長期產品邊界，原因是：

- 它容易把 UI 流程綁死在 Python 內部細節上
- 它不是預期中的最終遊戲呈現層
- 它會讓 app-shell 邏輯不斷吸收本該屬於遊戲層的責任

## 8. 舊 package 與遷移策略

`app/`、`game_content/`、`ui/` 目前仍然存在，因為專案需要過渡路徑。

現階段應這樣理解：

- `app/`：相容 shim layer
- `game_content/`：新 `content/` 的相容 shim
- `ui/`：過渡期間保留的 PySide6 實作

這是刻意的安排。骨架重構先做邊界切分，不在同一輪同時強迫整個 UI 完整搬遷。

## 9. 技術選型

### 9.1 Python

保留為核心邏輯語言，因為：
- 主要規則已存在於此
- 測試與迭代效率較高
- 較容易集中管理遊戲規則

### 9.2 PySide6

目前仍保留，因為：
- 適合快速建立內部工具與 demo
- 對編輯器型 workflow 很實用
- 現有程式已經建立在其上

目前定位：
- 支援中的 client
- 不是最終產品架構邊界

### 9.3 Godot

作為正式遊戲前端方向，原因是：
- 更適合承接 scene flow、呈現與遊戲體驗
- 比目前桌面工具型 shell 更符合最終產品型態

目前定位：
- `integration/` 的預期 consumer
- 尚未持有遊戲規則主控權

### 9.4 Wasm Judge 路徑

Wasm judge 仍然重要，因為它提供：

- 更可控的執行環境
- 更清楚的 sandbox 邊界
- 較穩定的遊戲判定基礎

## 10. 對後續開發的直接影響

基於目前架構，後續技術工作應依序進行：

1. 穩定骨架與相容路徑。
2. 在 `integration/contracts/` 定義正式契約。
3. 讓 `GameSession` 輸出正式 contract state。
4. 讓 clients 改成消費 contract 邊界。
5. 補上 bridge 基礎設施給外部前端使用。

這個順序可以減少重工，也能避免 Godot 直接耦合到尚未穩定的 Python 內部結構。

# Godot Client Structure Plan

- 版本：`0.1`
- 日期：`2026-03-15`
- 狀態：規劃中
- 前置完成：`godot_poc` 已驗證 bridge / reset / advance / submit_level 基本可行

## 1. 目的

本計畫的目標不是繼續擴充 POC，而是把目前已驗證可行的 Godot 接線，收斂成下一階段可維護、可擴充的正式 client 骨架。

這一輪要回答的核心問題是：

- Godot 端應如何切責任，避免所有流程都堆在單一 `main.gd`
- Godot 端應如何消費 `GameState`，而不是直接依賴 raw dictionary
- challenge UI、scene UI、submission feedback 應如何拆分成可持續演進的結構

## 2. 為什麼現在做

`godot_poc` 已經驗證以下事項：

- Godot 可啟動 Python `stdio bridge`
- `reset` / `advance` / `submit_level` 可以往返
- `GameState` 可被 Godot 消費
- `last_submission` 與錯誤訊息可顯示
- Python judge 實際生效，不再只是假過關

這代表目前的主要風險，已經不再是 bridge 可不可行，而是 Godot 端如果繼續停留在單檔 POC 腳本，後續一定會快速失控。

## 3. 本階段目標

本階段目標如下：

- 將 Godot client 拆成清楚的責任模組
- 建立 Godot 側自己的 state / view model 邊界
- 讓 scene flow、challenge flow、submission feedback 不再耦合在單一腳本
- 為後續正式 UI、美術、動畫、Blockly 方向保留可替換空間

## 4. 明確不在本輪處理

這一輪刻意不處理：

- Godot 最終視覺風格
- 動畫、轉場、音效
- 存檔 / 恢復
- 完整 quest navigation 系統
- Blockly 正式整合
- 正式產品級 editor 體驗
- 多語系與內容管線優化

## 5. 建議目標結構

建議 Godot client 至少拆成以下責任：

- `BridgeClient`
  - 啟動 Python subprocess
  - 管理 stdin/stdout request-response
  - 回傳 bridge response

- `BridgeStateStore`
  - 保存最近一次成功的 `GameState`
  - 保存最近一次錯誤訊息
  - 提供簡單的唯讀狀態入口

- `StateMapper`
  - 將 raw `GameState` dictionary 轉為 Godot 側 view model
  - 收斂 scene / challenge / feedback / actions 的顯示規則

- `ScenePanel`
  - 只負責 scene mode 顯示
  - 不直接發送 action

- `ChallengePanel`
  - 顯示 current level
  - 管理 code input
  - 發送 `submit_level`

- `FeedbackPanel`
  - 顯示 submission 結果與錯誤訊息

- `MainController`
  - 接收 bridge response
  - 更新 store
  - 驅動 panels refresh
  - 處理 `advance` / `reset` / `submit_level`

## 6. 設計原則

### 6.1 Godot 只吃 integration 邊界

Godot 端只透過 `stdio bridge` 消費：

- `GameState`
- `PlayerAction`
- response envelope

不要讓 Godot 直接依賴 Python 內部模組或規則物件。

### 6.2 UI 不直接解析全部 raw dictionary

`main.gd` 不應長期直接使用 `state.get(...)` 決定全部畫面。
應透過 mapper 先整理出 Godot 側穩定的顯示模型。

### 6.3 分離顯示與互動

- panel 負責顯示
- controller 負責 action
- store 負責狀態保存

避免 panel 自己同時發 request、解析 response、更新全域畫面。

### 6.4 保留替換空間

未來不論是：

- 改正式 code editor
- 接 Blockly
- 做多 panel layout
- 加動畫與演出

都應能在不重寫 bridge / state handling 的前提下演進。

## 7. 分階段落地

### Phase 1. 拆出基礎 client 結構

目標：把目前 `main.gd` 的責任拆開。

工作項目：

1. 抽出 `BridgeStateStore`
2. 抽出 `StateMapper`
3. 將 `main.gd` 改成 controller 角色
4. 讓 state render 不再直接散落在 controller 內

完成標準：

- `main.gd` 明顯變薄
- state 更新與畫面更新責任切開
- 保持現有 `reset` / `advance` / `submit_level` 行為不退化

### Phase 2. 拆出 scene / challenge / feedback panels

目標：讓不同 mode 的 UI 不再堆在單一 scene script。

工作項目：

1. 建立 `ScenePanel`
2. 建立 `ChallengePanel`
3. 建立 `SubmissionFeedbackPanel`
4. 讓 controller 只負責分發資料與事件

完成標準：

- scene 與 challenge 區域可以獨立更新
- feedback 可單獨演進
- UI 結構比目前 POC 更接近正式 client

### Phase 3. 收斂正式互動骨架

目標：為下一階段正式 Godot client 開發建立穩定入口。

工作項目：

1. 明確定義 Godot 側 action flow
2. 明確定義 view model shape
3. 明確記錄哪些欄位是 UI 正式依賴
4. 將 POC 過渡命名整理成正式結構命名

完成標準：

- Godot 端不再是驗證腳本集合
- 有清楚的 controller / store / panel 邊界
- 後續可以開始接正式 UI 與產品需求

## 8. Ticket 建議

### GCS-1 建立 BridgeStateStore 與 StateMapper

- 類型：frontend architecture
- 目標：把 raw `GameState` 轉成 Godot view model

### GCS-2 拆出 MainController 與 panel 更新流程

- 類型：frontend architecture
- 目標：`main.gd` 不再同時處理所有責任

### GCS-3 拆出 ScenePanel / ChallengePanel / FeedbackPanel

- 類型：frontend integration
- 目標：畫面結構可持續擴充

### GCS-4 定義正式 Godot client 的最小資料依賴面

- 類型：integration design
- 目標：明文化 Godot 正式依賴的 contract 欄位

## 9. 驗收標準

本階段完成後，應能確認：

1. Godot client 已不再依賴單一大型 POC 腳本
2. `GameState` 已先經過 mapper 再驅動畫面
3. scene / challenge / feedback 可獨立維護
4. `reset` / `advance` / `submit_level` 流程在新骨架下仍可正常工作
5. 下一階段可開始做正式 UI，而不是繼續修 POC 結構

## 10. 與既有計畫的關係

- `godot_poc_plan.md`
  - 負責驗證這條技術路徑可不可行

- 本計畫
  - 負責把可行的 POC 收斂成可持續開發的 Godot client 骨架

- 未來若進入正式產品前端階段
  - 應再新增更高層的 Godot gameplay / UI implementation plan
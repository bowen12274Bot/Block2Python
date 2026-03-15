# Godot POC Plan

- 版本：`0.1`
- 日期：`2026-03-14`
- 狀態：規劃中
- 前置完成：`integration contract`、`stdio bridge MVP`

## 1. 目的

本計畫的目標是用最小成本驗證：

- Godot 能否作為 `GameState` / `PlayerAction` 的外部 consumer
- Godot 能否透過 Python `stdio bridge` 穩定收發 JSON
- 目前的 integration contract 是否足以支撐下一階段正式 client 開發

這份計畫是驗證用 POC，不是正式 Godot client 開發計畫。

## 2. 為什麼現在做

目前這個 repo 已完成以下前置：

- `GameSession` 已能輸出標準化 `GameState`
- `PlayerAction` / `GameState` contract 已建立
- serializer / dispatcher 已實作
- `stdio bridge` MVP 已實作
- bridge protocol 與 Godot 接入 guide 已補齊

這代表專案已經離開「資料契約建置中」的階段，進入「驗證外部 client 是否可接入」的階段。

## 3. POC 範圍

POC 只驗證最小 client 路徑。

包含：

- 啟動 Python bridge subprocess
- 透過 `stdin/stdout` 送出 request / 接收 response
- 解析 `ok / state / error`
- 支援 `advance`
- 支援 `submit_level`
- 支援 `reset`
- 根據 `GameState.mode` 切換 `scene` / `challenge`
- 顯示 `last_submission` 與錯誤訊息

不包含：

- 正式 UI 美術與動畫
- 複數 scene 系統與完整 routing
- save/load
- `restart_quest`
- request id / response correlation
- 完整 Godot domain model
- 正式產品級 UX

## 4. 驗收標準

POC 完成後，應可確認以下事項：

1. Godot 可以啟動 `python -m block2python.integration.bridge_stdio.server`
2. Godot 可以傳送合法 JSON request
3. Godot 可以收到並解析 bridge response
4. Godot 可以顯示 `scene` 模式資料
5. Godot 可以顯示 `challenge` 模式資料
6. Godot 可以送出 `submit_level` 並顯示 `last_submission`
7. Godot 可以送出 `reset` 並回到 quest 起點
8. bridge 回傳 `ok = false` 時，Godot 不會誤覆蓋本地 state

## 5. 建議架構

Godot POC 建議只拆成以下幾個最小責任：

- `BridgeClient`
  - 啟動與關閉 Python subprocess
  - 寫入 JSON request
  - 讀取單行 JSON response

- `BridgeStateStore`
  - 保存最近一次成功的 `GameState`
  - 保存最近一次錯誤訊息

- `PocMainScene`
  - 顯示 mode / title / dialogue / challenge level
  - 提供 `Advance` / `Submit` / `Reset` 按鈕
  - 顯示 submission summary 或 error

POC 階段不需要先抽象成完整 UI framework。

## 6. 執行步驟

### Step 1. 建立 Godot bridge client skeleton

目標：

- 先證明 Godot 能啟動 Python bridge process
- 先證明 Godot 能送出 `reset`
- 先證明 Godot 能拿到初始 `GameState`

完成標準：

- Godot 內能成功發送：

```json
{
  "command": "reset"
}
```

- 並收到 `ok = true` 的 response

### Step 2. 建立最小 state parsing 與 state store

目標：

- 將 bridge response 轉成 Godot 側可用的最小 state
- 只解析 POC 真正需要的欄位

至少包含：

- `mode`
- `node_id`
- `node_title`
- `scene`
- `challenge`
- `available_actions`
- `last_submission`
- `progress`

完成標準：

- 成功 response 會更新本地 state
- 錯誤 response 只更新錯誤訊息，不覆蓋本地 state

### Step 3. 建立最小 POC 畫面

目標：

- 用單一 Godot scene 顯示目前狀態
- 不追求正式 UI，只追求可驗證

建議畫面元素：

- `mode` label
- `node_title` label
- `scene dialogue` text area
- `challenge current_level_id` label
- `submission / error` text area
- `Advance` button
- `Submit` button
- `Reset` button

完成標準：

- 可以在同一個畫面中觀察 state 變化
- 可以手動完成 scene -> challenge -> submit -> reset 流程

### Step 4. 補 smoke 驗證流程

目標：

- 寫一份短的操作驗證流程
- 確認 POC 是否足以支持下一階段正式 Godot client 開發

至少驗證：

1. 啟動 Godot
2. 連到 Python bridge
3. `reset`
4. 連續 `advance`
5. 進入 challenge
6. `submit_level`
7. 顯示 `last_submission`
8. `reset` 後回到起點

## 7. Ticket 建議

### GPOC-1 建立 bridge client skeleton

- 類型：integration
- 目標：Godot 可啟動 Python bridge 並完成單次 `reset`

### GPOC-2 建立最小 state parser / store

- 類型：integration
- 目標：Godot 可正確保存最新 `GameState`

### GPOC-3 建立最小 POC scene

- 類型：frontend integration
- 目標：Godot 可手動操作 `advance` / `submit_level` / `reset`

### GPOC-4 補 smoke 驗證與限制記錄

- 類型：verification
- 目標：明確確認 POC 可行性與後續缺口

## 8. 依賴與輸入

POC 依賴以下既有輸出：

- `docs/specs/bridge_stdio_protocol_v0_1.md`
- `docs/development_plans/godot_bridge_client_guide.md`
- `src/block2python/integration/bridge_stdio/server.py`
- `src/block2python/integration/contracts/`

## 9. 完成後的決策點

POC 完成後，應回答以下問題：

1. 目前的 contract 是否足夠給 Godot 使用
2. `stdio bridge` 是否足夠穩定作為下一階段 client 邊界
3. 下一步應優先做：
   - 正式 Godot client 結構
   - bridge protocol 擴充
   - save/load

## 10. 明確不在本輪處理

以下項目刻意不放進這輪 POC：

- Godot 最終 UI 版型
- 美術資產導入
- 動畫與演出系統
- 完整 quest navigation
- 存檔與恢復
- `restart_quest` action 實作
- multiplayer / remote bridge

POC 的目的不是完成產品，而是證明這條技術路徑成立。

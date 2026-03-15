# Godot 畫面分離計畫

- 文件版本：0.1
- 更新日期：2026-03-15
- 文件定位：定義 Godot 主地圖頁與關卡頁分離的範圍、責任切分與落地順序

## 1. 目的

本文件的目標不是重做 `godot_quest_map_vertical_slice`，而是把目前已打通的 vertical slice，從「單頁整合驗證面板」收斂成更像正式遊戲的多畫面 flow。

這一輪要解決的核心問題是：

- 主地圖頁和關卡頁目前混在同一個場景，資訊密度過高
- 玩家缺少「從地圖進入關卡，再回到地圖」的明確頁面切換感
- 後續若要做正式 UI、美術、對話框與 editor 頁面，現在的單頁整合 layout 會成為阻力

## 2. 為什麼現在做

目前已完成的前置如下：

- Godot quest map vertical slice 已跑通
- 新的 demo / practice 關卡內容已接上
- `submit -> cleared -> next node -> return to map` 主流程已成立
- Godot 端已有 `QuestMapController`、`StateMapper`、`ChallengePanel`、`ScenePanel` 等骨架

這代表目前主要瓶頸已從「流程能不能跑」轉為「畫面結構是否符合正式前端方向」。

## 3. 本階段目標

- 將主地圖頁與 node flow 頁面分離
- 建立最小的畫面切換 coordinator / router
- 保持現有 integration contract 與 quest state 不變
- 為後續正式對話頁、編輯頁、美術與轉場預留空間

## 4. 明確不在本輪處理

這一輪刻意不處理：

- 最終版美術
- 正式動畫與 camera 運鏡
- 多章節導航
- 存檔 / 讀檔
- Blockly 正式整合
- 進階 UI polish
- 完整 debug / devtool 系統

## 5. 目前問題定義

目前 [quest_map.tscn](/e:/bowen.code/project/Block2Python/godot_poc/scenes/quest_map.tscn) 同時承擔：

- 主地圖顯示
- scene flow 顯示
- challenge flow 顯示
- feedback 顯示
- debug 顯示

這種做法有助於驗證 vertical slice，但不是正式遊戲的頁面結構。

## 6. 建議目標結構

### 6.1 `QuestMapScene`

職責：

- 只負責地圖節點、節點狀態、目前位置與可進入節點
- 不直接承擔 challenge 輸入區
- 不直接承擔 scene 對話內容顯示

### 6.2 `SceneFlowScene`

職責：

- 顯示 scene node 對話與敘事內容
- 提供 `Advance` 或 `Continue` 行為
- 完成後將控制權交回 coordinator

### 6.3 `ChallengeScene`

職責：

- 顯示題目標題、prompt、code input、submission feedback
- 提供 `Submit`
- 完成 challenge 後回到 coordinator

### 6.4 `FlowCoordinator`

職責：

- 根據目前 `GameState.mode` 與 `node_id` 決定顯示哪個場景
- 管理：
  - `QuestMapScene -> SceneFlowScene`
  - `QuestMapScene -> ChallengeScene`
  - `SceneFlowScene -> QuestMapScene`
  - `ChallengeScene -> QuestMapScene`
- 保持與 `BridgeClient` / `StateMapper` 的整合邊界

## 7. 建議互動流程

### 7.1 主流程

`Map Scene -> Scene Flow Scene -> Map Scene -> Challenge Scene -> Map Scene`

### 7.2 第一版原則

- 先做明確換頁，不先追求精緻 transition
- 按節點進入時，畫面要真的切離地圖頁
- challenge 結束後回地圖時，要用最新 `GameState` refresh
- debug 資訊保留為開發用途，但不再佔據主畫面

## 8. 分階段落地

### Phase 1. Map 與 Flow 畫面切開

目標：

- 把地圖頁與 flow 頁拆成不同 scene

工作項目：

1. 建立 `SceneFlowScene`
2. 建立 `ChallengeScene`
3. 精簡 `QuestMapScene`，讓它只保留地圖頁職責

完成標準：

- 玩家在地圖頁不再同時看到 code input 與 feedback
- 進入 scene/challenge 時會切到對應畫面

### Phase 2. 建立 coordinator / router

目標：

- 建立 Godot 端最小畫面切換骨架

工作項目：

1. 建立 `FlowCoordinator`
2. 決定 bridge response 後的 routing 規則
3. 建立返回地圖的統一路徑

完成標準：

- routing 不再散落在單一 scene script
- `submit / advance / reset` 後的畫面切換一致

### Phase 3. 收斂頁面資料依賴面

目標：

- 讓每種畫面只吃自己需要的 view model

工作項目：

1. 地圖頁只吃 map view model
2. scene 頁只吃 scene view
3. challenge 頁只吃 challenge / feedback view
4. 補文件，明文化每種 scene 的依賴資料

完成標準：

- UI 層責任更清楚
- 後續可以獨立發展 map、scene、challenge 三種頁面

## 9. Ticket 建議

### GSS-1 拆出 QuestMapScene / SceneFlowScene / ChallengeScene

- 類型：frontend structure
- 目標：主地圖與關卡頁不再共用單一整合場景

### GSS-2 建立 FlowCoordinator

- 類型：frontend routing
- 目標：集中管理畫面切換與返回地圖邏輯

### GSS-3 收斂各頁面資料依賴面

- 類型：integration design
- 目標：每種 scene 只依賴自己的 view model

### GSS-4 驗收換頁式 vertical slice

- 類型：verification
- 目標：確認 `Map -> Scene -> Map -> Challenge -> Map` 成立

## 10. 驗收標準

本階段完成後，應能確認：

1. 主地圖頁與關卡頁已正式分離
2. scene / challenge 不再直接嵌在地圖頁下方
3. `advance` 與 `submit` 可驅動正確頁面切換
4. challenge 完成後可帶著最新狀態回地圖
5. 這套結構可作為正式 Godot gameplay UI 的下一步基礎

## 11. 與既有文件的關係

- `godot_client_structure_plan.md`
  - 收斂 Godot client 程式骨架

- `godot_quest_map_vertical_slice_plan.md`
  - 驗證主地圖 vertical slice 可玩性

- 本文件
  - 處理畫面分離與前端 flow 結構

## 12. 下一步

本文件確立後，建議依序執行：

1. 先做 `GSS-1`
2. 再做 `GSS-2`
3. 最後用 `GSS-3` 與 `GSS-4` 收斂成正式多頁面 flow

# Godot Quest Map Vertical Slice 計畫

- 文件版本：0.1
- 更新日期：2026-03-15
- 文件定位：定義 Godot 主場景地圖、節點進出流程，以及最小內容重寫切片的範圍與落地順序

## 1. 目的

本文件的目標不是再驗證 `stdio bridge` 或 `GameState` contract，而是定義 Godot 正式前端的第一個可玩切片。

這個切片要先把以下事情打通：

- 以 Godot 呈現節點式主地圖
- 從主地圖點選節點並進入 node flow
- 從示範 scene / challenge 推進到後續練習關
- 完成後回到主地圖並刷新節點狀態
- 以最小內容重寫取代前段遺留關卡，讓新流程有一組真正服務目前需求的資料

本文件的核心原則是：先做出一條能玩、能驗證、能支撐後續前端演進的最小主流程，不在本輪追求完整地圖系統或完整章節內容。

## 2. 為什麼現在做

目前專案已完成的前置如下：

- integration contract 已建立
- `stdio bridge` 已可由 Godot 正常消費
- `reset / advance / submit_level` 已在 Godot POC 驗證可行
- Godot client 骨架已收斂成 `MainController + StateMapper + Panels`
- Godot 正式依賴的 contract surface 已明文化

這代表目前的主要阻塞點，不再是「技術接線是否可行」，而是：

- Godot 是否已經能承接正式主場景責任
- 現有遺留 quest / level 內容是否適合現在的產品方向
- 是否能用一組最小但正確的新內容，驅動 Godot 主流程向前

## 3. 本切片要回答的問題

- Godot 能否作為正式主地圖入口，而不是只做 POC 操作面板
- 節點式地圖、scene node 與 challenge node 之間能否順暢切換
- 玩家能否從主地圖進入示範關，再進入後續練習關並回到地圖
- Godot 是否能依 `GameState` 正確刷新節點狀態與進度
- 目前是否能用一小段重寫過的內容，取代遺留關卡支撐這條新流程

## 4. 切片範圍

### 4.1 必含流程

1. 進入 Godot 主場景地圖
2. 顯示目前 quest 的最小節點網路
3. 點選目前可進入的節點
4. 進入一個示範 scene node
5. 進入一個示範 challenge node
6. 再進入 1 到 2 個後續練習 challenge
7. 完成或離開後回到主地圖
8. 地圖依最新 `GameState` 更新節點狀態

### 4.2 本切片至少包含的內容

- 一個 Godot 主地圖場景骨架
- 一組最小 quest map view model
- 一個 scene node
- 一個示範 challenge node
- 一到兩個練習 challenge node
- 一次從地圖進入 node flow 再回到地圖的完整路徑
- 一份專門服務此切片的最小內容資料

### 4.3 本切片暫不包含

- 多 quest / 多章節導航
- 正式美術、動畫、音效
- 可拖曳或可縮放地圖
- 複雜 camera / 過場系統
- 存檔 / 讀檔
- Blockly 正式整合
- 大量題庫重寫
- 完整內容管線重整

## 5. 內容重寫範圍

目前部分關卡與題目來自前段遺留設計，未必對齊現在的 Godot 主流程與產品方向。

因此本切片必須包含一小段內容重寫，但重點不是擴大題庫，而是提供一組最小、正確、可支撐新流程的資料。

### 5.1 重寫目標

- 讓節點式主地圖有對應的 quest / node 資料
- 讓示範關與練習關形成可理解的學習節奏
- 讓題目敘事與任務理由更貼近目前主場景 flow
- 讓 Godot 前端不是被舊資料牽著走

### 5.2 最小內容建議

- `map-entry`
  - 主地圖入口節點

- `scene-city-alarm`
  - 第一段主場景敘事
  - 說明城市故障與目前任務

- `challenge-demo-basic-io`
  - 第一個示範 challenge
  - 目標：讓玩家理解輸入 / 輸出與提交流程

- `challenge-practice-basic-io-01`
  - 第一個練習題

- `challenge-practice-basic-io-02`
  - 第二個練習題

### 5.3 本輪內容原則

- 題目數量少，但必須順流程
- 題目敘事清楚，但不追求完整世界觀文本
- 優先支援 Godot 主流程，不追求一次重寫全部舊資料

## 6. 建議系統切分

### 6.1 Godot 前端

- `QuestMapScene`
  - 主地圖場景
  - 負責呈現節點、連線、目前位置與可進入狀態

- `QuestMapController`
  - 接收 `GameState`
  - 驅動地圖 refresh
  - 處理點節點、進 node flow、回地圖

- `QuestMapViewModelMapper`
  - 將 `GameState` 轉成地圖專用 view model
  - 收斂 node status / available node / current node / selected node

- `NodeFlowRouter`
  - 根據 node 類型決定顯示 scene flow 或 challenge flow

### 6.2 內容資料

- 最小 quest graph 定義
- 最小 scene 文本
- 最小 challenge / level 題組

### 6.3 integration 邊界

Godot 仍只透過既有 integration 邊界互動：

- `GameState`
- `PlayerAction`
- response envelope

本輪不新增 Godot 專用私有後門。

## 7. 流程定義

### 7.1 主流程

`Quest Map -> Scene Node -> Demo Challenge -> Practice Challenge A -> Practice Challenge B -> Return to Map`

### 7.2 最小狀態更新需求

每次 node flow 結束後，地圖至少要能反映：

- 當前節點
- 已完成節點
- 可進入的下一節點
- challenge 是否 cleared

### 7.3 第一版互動原則

- 點節點即可進入，不先做複雜節點資訊面板
- scene node 先用簡化敘事 panel 呈現
- challenge node 沿用現有 challenge 提交骨架
- 回地圖機制以可用為主，不先做精緻轉場

## 8. 分階段落地

### Phase 1. 主地圖骨架

目標：

- 建立 Godot 主地圖場景
- 能看到最小節點網路與目前節點狀態

工作項目：

1. 建立 `QuestMapScene`
2. 建立最小節點 UI 元件
3. 建立地圖 view model mapper
4. 用 mock / 現有 state 驗證節點狀態顯示

完成標準：

- Godot 中可看到節點式地圖骨架
- 可分辨目前節點、已完成節點、可進入節點

### Phase 2. 點節點與進出 node flow

目標：

- 從主地圖進入 scene / challenge flow
- 完成後可回主地圖

工作項目：

1. 建立 node selection / click handling
2. 建立 `NodeFlowRouter`
3. 串接現有 scene / challenge panels
4. 完成後刷新主地圖

完成標準：

- 點擊可用節點可進入對應 flow
- 離開 flow 後回主地圖且狀態刷新

### Phase 3. 最小內容重寫

目標：

- 用新需求導向的最小內容取代前段遺留關卡

工作項目：

1. 建立最小 quest node 結構
2. 補一段 scene 文本
3. 建立一個示範 challenge 與兩個練習題
4. 確認內容與 Godot flow 對齊

完成標準：

- 不再依賴舊遺留關卡才能跑通主流程
- Godot vertical slice 有一組專門對應的新內容

### Phase 4. 垂直切片驗收

目標：

- 從主地圖走完一條完整主流程

至少驗證：

1. 啟動 Godot 並進入主地圖
2. 點選第一個 scene node
3. 進入示範 challenge
4. 提交並通過
5. 進入後續練習題
6. 回到地圖
7. 節點狀態正確更新

## 9. Ticket 建議

### GQM-1 建立 Quest Map 主場景骨架

- 類型：frontend architecture
- 目標：Godot 端出現可刷新的節點式主地圖

### GQM-2 建立地圖 view model 與 node status 映射

- 類型：frontend integration
- 目標：地圖能依 `GameState` 顯示當前節點與可進入節點

### GQM-3 串接點節點進入 scene / challenge flow

- 類型：frontend flow
- 目標：從主地圖進入 node flow，再回到主地圖

### GQM-4 重寫最小 quest / challenge 內容切片

- 類型：content vertical slice
- 目標：建立一組服務 Godot 主流程的新內容

### GQM-5 驗收主地圖 vertical slice

- 類型：verification
- 目標：確認地圖、節點、challenge 與狀態回寫形成完整可玩流程

## 10. 驗收標準

本計畫完成後，應能確認：

1. Godot 已成為主地圖與節點流程的正式入口
2. 玩家可從地圖進入示範 node 與練習 node
3. Godot 可在 node flow 結束後回到主地圖
4. 地圖會依最新 `GameState` 正確刷新節點狀態
5. 本流程使用的是一組最小但重新整理過的內容，而不是單純沿用舊遺留關卡
6. 這條 vertical slice 可作為後續正式 Godot gameplay / UI 開發基準

## 11. 與既有文件的關係

- `godot_poc_plan.md`
  - 驗證 Godot 是否能消費 bridge 與 contract

- `godot_client_structure_plan.md`
  - 收斂 Godot client 的程式骨架

- 本文件
  - 定義第一個以 Godot 主地圖為核心的可玩 vertical slice

- `godot_client_contract_surface_v0_1.md`
  - 定義 Godot client 目前正式依賴的 contract surface

## 12. 下一步

本文件確立後，建議下一步依序執行：

1. 先做 `GQM-1` 與 `GQM-2`
2. 再做 `GQM-4`，準備最小內容切片
3. 最後用 `GQM-3` 與 `GQM-5` 把主流程打通並驗收

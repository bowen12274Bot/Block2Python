# Godot 地圖整合計畫

- 文件版本：0.1
- 更新日期：2026-03-18
- 文件定位：定義如何把 level group 格式與空骨架掛到 Godot 地圖與節點流程上

## 1. 目的

本文件處理的不是 level 格式本身，而是：

- Godot 地圖如何承載 3 個 level group
- group 與節點、story、challenge 頁面的關係
- 玩家如何從地圖看到並進入這 3 組內容

## 2. 前置假設

本文件預設：

- `godot_map_completion_plan.md` 已先固定 3 組 `1 demo + 5 practice` 的格式與空骨架
- Godot 端仍沿用目前：
  - 地圖頁
  - 劇情頁
  - 關卡頁

## 3. 本階段目標

- 在地圖上呈現 3 個 level group
- 定義 group 對應的 node / scene / challenge 進出規則
- 讓地圖可作為這 3 組內容的正式入口

## 4. 明確不在本輪處理

這一輪先不做：

- 最終美術
- 多城市世界地圖
- 存檔
- Blockly 正式玩法
- 工具包 / 電池規則接入

## 5. 需要解決的問題

1. 地圖上每個 group 要怎麼顯示
2. demo 與 practice 在地圖上要不要拆成多個節點
3. group 完成後如何解鎖下一組
4. 地圖回來後如何反映目前進度

## 6. 建議地圖結構

每個 group 至少對應：

- 一個進入 story / intro 的節點
- 一個 demo challenge 節點
- 一個 practice challenge 節點

practice challenge 內部再承接 5 題 level。

## 7. 分階段落地

### Phase 1. 地圖上定義 3 組 group 節點

目標：

- 地圖上能看見 3 組關卡主結構

### Phase 2. group 與頁面 flow 對接

目標：

- 玩家可從地圖進入各 group 的 scene / challenge flow

### Phase 3. 地圖進度刷新驗證

目標：

- 完成一組後，地圖能正確反映解鎖與下一步

## 8. Ticket 建議

### GMI-1 定義 group 對應的地圖節點結構

### GMI-2 串接 group 與 Godot 頁面 flow

### GMI-3 驗證 3 組地圖流程

## 9. 驗收標準

本計畫完成後，應能確認：

1. 地圖可承載 3 個 level group
2. 玩家可從地圖進入各組 demo / practice
3. group 完成後地圖狀態會更新

## 10. 與既有文件的關係

- `godot_map_completion_plan.md`
  - 定義 level group 格式與空骨架

- 本文件
  - 定義如何把這套格式掛到 Godot 地圖上

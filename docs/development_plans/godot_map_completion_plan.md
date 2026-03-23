# Godot Level 格式與空骨架計畫

- 文件版本：0.2
- 更新日期：2026-03-18
- 文件定位：定義 3 個 level group 的格式規格、命名規則與空內容骨架，不在本輪填滿正式題目內容

## 1. 目的

本文件的目標不是直接產出完整題庫，而是先把未來地圖要承載的 level 結構定稿。

這一輪先做的是：

- 定義 3 個 level group 的固定格式
- 定義每個 group 內 `1 demo + 5 practice` 的結構
- 定義命名、資料欄位、cases 目錄與 placeholder 內容方式
- 建立可被 Godot 地圖與 flow 消費的空骨架

## 2. 為什麼現在做

目前專案已有：

- Godot 地圖入口
- 劇情頁 / 關卡頁分離
- 可跑通的最小 vertical slice

但如果現在直接開始寫 18 題內容，很容易出現：

- 題目格式之後改一次就要重寫很多檔案
- 地圖結構與內容結構彼此綁死
- demo / practice 的節奏還沒固定就先把題庫寫滿

所以現在應先定：

- level group 格式
- content pipeline 結構
- Godot 端未來要依賴的命名與節點規則

## 3. 本階段目標

- 建立 3 個 level group 的固定格式
- 每個 group 固定包含：
  - 1 個 demo challenge
  - 5 個 practice challenges
- 為這 18 題建立空骨架與 placeholder
- 不先追求正式題目內容，只先讓格式能支撐後續擴寫

## 4. 明確不在本輪處理

這一輪先不做：

- 正式題目文案
- 完整 testcase 設計
- Blockly 正式玩法
- 工具包 / 電池規則落地
- 完整章節劇情
- UI 美術與轉場

## 5. 固定格式目標

## 5.1 Level Group 結構

每個 level group 固定使用：

- `demo`
- `practice-01`
- `practice-02`
- `practice-03`
- `practice-04`
- `practice-05`

總共 3 個 group：

- `group-01`
- `group-02`
- `group-03`

## 5.2 Challenge 命名規則

建議固定命名：

- `challenge-group-01-demo`
- `challenge-group-01-practice`
- `challenge-group-02-demo`
- `challenge-group-02-practice`
- `challenge-group-03-demo`
- `challenge-group-03-practice`

其中 practice challenge 內部可對應 5 題 level ids。

## 5.3 Level ID 命名規則

建議固定命名：

- `group-01-demo`
- `group-01-practice-01`
- `group-01-practice-02`
- `group-01-practice-03`
- `group-01-practice-04`
- `group-01-practice-05`

其餘 group 依序類推。

## 5.4 Cases 目錄規則

每題固定一個 cases 目錄：

- `assets/levels/cases/group-01-demo/`
- `assets/levels/cases/group-01-practice-01/`

每題至少允許 placeholder testcase：

- `01.in`
- `01.out`

## 5.5 Placeholder 原則

本輪 placeholder 應滿足：

- loader 可載入
- Godot 可顯示
- judge 可在之後補實際題目時直接替換

本輪 placeholder 不要求：

- 正式教學品質
- 完整難度曲線
- 最終 prompt 文案

## 6. 建議資料切分

### 6.1 Levels

每一題都建立：

- level yaml
- cases 目錄

### 6.2 Challenges

每個 group 建立：

- 1 個 demo challenge
- 1 個 practice challenge

### 6.3 Nodes / Quest

每個 group 至少要能對應：

- 進入 demo 的節點
- 進入 practice 的節點
- 完成後回主地圖的節點關係

## 7. 分階段落地

### Phase 1. 定格式

目標：

- 把 3 個 group 的命名與檔案結構固定下來

工作項目：

1. 定 group 命名
2. 定 challenge 命名
3. 定 level 命名
4. 定 cases 目錄規則

完成標準：

- 之後新增題目時不再需要重新決定命名與目錄結構

### Phase 2. 建空骨架

目標：

- 先產生 3 組 `1 demo + 5 practice` 的空內容骨架

工作項目：

1. 建立 placeholder level yaml
2. 建立 placeholder cases
3. 建立對應 challenge yaml
4. 更新 index / content 讓它們可被載入

完成標準：

- 3 組骨架存在，且結構一致

### Phase 3. 驗證格式可用

目標：

- 確認這套格式可供 Godot 與 Python 流程後續使用

至少驗證：

1. content loader 可讀
2. challenge/runtime 不會因空骨架格式報錯
3. Godot 地圖規劃可引用這組結構

## 8. Ticket 建議

### GMCF-1 定義 3 組 level group 命名與格式

- 類型：content schema
- 目標：固定 `1 demo + 5 practice` 結構

### GMCF-2 建立 3 組空骨架

- 類型：content scaffold
- 目標：為 18 題建立 placeholder content

### GMCF-3 驗證格式可供地圖與 flow 使用

- 類型：verification
- 目標：確認這套格式能支撐後續地圖整合

## 9. 驗收標準

本計畫完成後，應能確認：

1. 3 個 level group 的格式已固定
2. 每組都具備 `1 demo + 5 practice` 骨架
3. 命名、cases 與 challenge 對應方式一致
4. 後續可以在不重改格式的情況下補正式題目內容

## 10. 與既有文件的關係

- `godot_quest_map_vertical_slice_plan.md`
  - 定義最小可玩切片

- `godot_screen_separation_plan.md`
  - 定義地圖頁與關卡頁分離

- 本文件
  - 先固定未來要掛到地圖上的 level group 格式

## 11. 下一步

本文件確立後，建議依序執行：

1. 先做 `GMCF-1`
2. 再做 `GMCF-2`
3. 最後用 `GMCF-3` 驗證格式可用

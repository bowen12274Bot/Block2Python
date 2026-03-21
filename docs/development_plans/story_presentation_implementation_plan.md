# Story Presentation Implementation Plan

- 版本：`v0.2`
- 日期：`2026-03-22`
- 狀態：草案
- 目的：規劃正式劇情演出場景的文件、資料模型、Godot UI 與整合步驟。

## 1. 背景

目前 `scene_flow_screen.tscn` 與 `scene_panel.gd` 主要是文字型劇情頁，足夠驗證 flow，但不足以承接產品文件要求的正式劇情演出。

已知需求來源包括：

- `docs/product/chapter_design.md`
- `docs/requirements.md`
- `docs/requirements/core/story_presentation_requirements.md`
- `docs/specs/story_presentation_scene_spec_v0_1.md`

本計畫的目標不是直接完成最終美術品質，而是先把正式演出骨架、資料接口與流程責任固定下來。

## 2. 目標

1. 建立可獨立演進的劇情演出畫面。
2. 讓 scene payload 足以描述背景、角色槽與焦點狀態。
3. 保持與既有 flow coordinator、page router、bridge 狀態流相容。
4. 讓後續更換美術與補劇情內容時，不必重做 UI 架構。
5. 讓同一套劇情頁可共用於開場劇情、主地圖 story 節點與未來結局劇情。

## 3. 非目標

以下不在此計畫第一輪範圍內：

- 分支選項系統
- Live2D / Spine / 骨架動畫
- 鏡頭系統
- 配音與音效系統
- 複雜轉場特效

## 4. 分階段實作

### Phase 1. 文件定稿與資料欄位收斂

目標：

- 先把產品需求、技術規格與實作邊界對齊
- 先完成資料骨架，而不是先做正式劇情 UI

工作：

- 整理正式劇情演出需求文件
- 確認 `scene_view` 第一版 shape
- 定義 `dialogue_blocks` 擴充方向
- 採用保留並擴充策略，延續 `portrait_id / expression / emphasis`
- 明確列出第一版不做的項目

完成標準：

- 產品、規格、計畫文件三者內容一致
- Godot mapper 已能產出 presentation-friendly `scene_view`
- sample scene 已能展示背景、左右角色與焦點切換資料

### Phase 2. Godot 畫面骨架

目標：

- 以現有 `scene_flow_screen` 為基礎，建立正式劇情演出版面

工作：

- 新增或改造背景層、角色層、對話框層
- 建立左右角色槽
- 建立名牌、正文與 continue hint
- 處理全畫面點擊推進

完成標準：

- 不接正式美術也能用 placeholder 畫面演示完整劇情閱讀流程

### Phase 3. Mapper 與資料相容層

目標：

- 讓 Godot UI 吃 presentation-friendly `scene_view`

工作：

- 擴充 mapper 產出新的 `scene_view`
- 保留舊資料形狀的 fallback
- 決定背景與角色資產 ID 到 Godot 資源的映射策略

完成標準：

- 劇情頁不再只依賴把所有段落壓成單一文字 body
- 舊 scene 資料仍可在過渡期運作

### Phase 4. Flow 整合

目標：

- 把正式劇情演出接回既有流程主控

工作：

- 檢查 `advance_requested`、`back_requested`、完成事件的責任邊界
- 明確定義劇情最後一段與 flow coordinator 的交接時機
- 驗證建角後開場劇情、地圖 story 節點與未來結局劇情都能共用同一套畫面

完成標準：

- 劇情完成後的 routing 清楚，不會回到中間狀態

## 5. 工作拆分建議

### TP-1 文件與 contract

- 補需求、規格、計畫文件
- 更新 README 索引
- 更新 `godot_client_contract_surface_v0_1.md`
- 更新 `game_slice_schema_v0_1.md`

### TP-2 Data skeleton

- 擴充 `dialogue_blocks` 欄位
- 更新 sample scene
- 調整 `game_flow_mapper.gd`
- 建立可相容舊資料的 `scene_view`

### TP-3 Presentation scene UI

- 改造 `scene_flow_screen.tscn`
- 視需要拆出 presentation panel script
- 建立 placeholder 資產掛點與 UI 狀態切換

## 6. 驗證重點

- schema、contract、scene spec、implementation plan 彼此對齊
- sample scene 欄位與規格一致
- mapper 可輸出 `hidden / dim / focus / silhouette` 四種角色狀態
- 舊資料仍可透過 fallback 產出基本可用的 `scene_view`
- `scene_view` 可同時支撐開場劇情、主地圖 story 節點與未來結局劇情

## 7. 風險

- 若過早把 scene schema 定得過死，後續會被美術與演出需求反推重做。
- 若 UI 直接吃 raw state，之後一加角色與背景欄位就會讓 panel 腳本快速失控。
- 若畫面骨架先做死在 placeholder 資產尺寸，後續換正式圖可能大幅重排。
- 若流程完成事件與 `advance` 動作語意不清，會在最後一段交接時出現重複前進或卡死。
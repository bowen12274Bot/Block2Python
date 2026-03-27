# 五關主地圖轉換計畫

- 版本：0.1
- 日期：2026-03-26
- 範圍：在延用目前穩定主地圖骨架的前提下，將現行三關主地圖流程擴充為五關主地圖流程。

## 1. 目標

近期目標不是全面替換現有主地圖流程架構，而是先把目前可運作的三關主地圖流程，穩定擴充成五關主地圖流程，並逐步把目前 `ai-track-*` 中承載的新五關題目與測資，併入這套正式流程中。

此計畫的前提如下：

- 目前的三關主流程是可運作且應優先保留的基線。
- 新的五關內容方向正確，應予以保留。
- 過渡階段應以降低 runtime 風險為優先，不應同時重寫主地圖骨架。

## 2. 決策

### 2.1 採用方向

以目前既有的主地圖骨架作為五關轉換的實作基底：

- `assets/game_content/quests/quest-main-map.yaml`
- `assets/game_content/map_routes/main-map-routes.yaml`
- `assets/game_content/nodes/main-map-nodes.yaml`
- `assets/game_content/challenges/challenge-group-*.yaml`
- `godot_poc/scripts/map/quest_map_mapper.gd`
- `godot_poc/scripts/map/quest_map_screen.gd`
- `godot_poc/scenes/quest_map_screen.tscn`

新的 `ai-track-*` 關卡先作為內容來源使用，而不是直接取代目前的主流程骨架，也不是最終會保留的正式命名。

### 2.2 不採用方向

現階段不直接把 `ai-track-*` 這套 level chain 升格成主地圖 runtime 骨架。

原因如下：

- `ai-track-*` 目前描述的是關卡先後關係，不是完整的主地圖流程。
- 現有 Godot 主地圖 UI 與 runtime projection 是以 `group` 為中心運作。
- 若現在直接切換到新骨架，將需要同時改 quest、nodes、routes、challenges、UI mapping 與 flow orchestration，風險過高。

## 3. 現況

### 3.1 目前穩定骨架

目前可玩的主流程以三個 group 為單位：

- `group-01`
- `group-02`
- `group-03`

每個 group 內部都採用以下流程：

- Story
- Demo
- Practice
- Result / 回主地圖

Godot 主地圖畫面目前也是依據 route state 轉出的 `group_views` 來顯示。

### 3.2 新五關內容形狀

新的五關內容目前為：

- `ai-track-input-gate`
- `ai-track-variable-base`
- `ai-track-if-canyon`
- `ai-track-loop-lab`
- `ai-track-bug-king-castle`

這些檔案目前是單關 level，靠以下欄位串起來：

- `prerequisite_level_ids`
- `next_level_ids`

這代表它們目前屬於內容層的 progression metadata，還不是完整主地圖流程定義。

## 4. 架構對應方式

本次轉換應採用「把五關內容映射到舊骨架」的方式，而不是先替換骨架。

### 4.1 實務對應規則

每一個主地圖 stage / group 對應一個正式學習關卡，而 `ai-track-*` 僅作為過渡期的內容來源。

建議對應如下：

- Stage 01 -> `Input Gate`
- Stage 02 -> `Variable Base`
- Stage 03 -> `If Canyon`
- Stage 04 -> `Loop Lab`
- Stage 05 -> `Bug King Castle`

對應的過渡內容來源如下：

- `ai-track-input-gate` -> Stage 01 / `Input Gate`
- `ai-track-variable-base` -> Stage 02 / `Variable Base`
- `ai-track-if-canyon` -> Stage 03 / `If Canyon`
- `ai-track-loop-lab` -> Stage 04 / `Loop Lab`
- `ai-track-bug-king-castle` -> Stage 05 / `Bug King Castle`

最終正式的五關名稱如下：

1. `Input Gate`
2. `Variable Base`
3. `If Canyon`
4. `Loop Lab`
5. `Bug King Castle`

### 4.2 Runtime 解釋

在過渡階段中，每一個 stage 仍可沿用目前 map system 的結構表示為：

- 一個地圖上的 group / stage 節點
- 一個 story node
- 一個 demo node 或 demo placeholder
- 一個 practice challenge 入口
- 一個 result / return node

重點在於：即使底層內容改為新五關，主地圖流程仍維持 group-based 的表示方式。

## 5. 實作策略

### Phase 1：把骨架由三關擴成五關

先擴充目前主地圖流程定義，讓系統支援五個 stage，而不是三個。

需要更新的檔案：

- `assets/game_content/quests/quest-main-map.yaml`
- `assets/game_content/map_routes/main-map-routes.yaml`
- `assets/game_content/nodes/main-map-nodes.yaml`
- `godot_poc/scripts/map/quest_map_mapper.gd`
- `godot_poc/scripts/map/quest_map_screen.gd`
- `godot_poc/scenes/quest_map_screen.tscn`

預期結果：

- 主地圖能渲染五個 stage 入口。
- runtime state 能表示五個 group / stage。
- 主地圖進度與狀態顯示不再假設只有三關。

### Phase 2：把 `ai-track-*` 內容併入正式五關

將既有 placeholder 或舊的 practice bundle，逐步替換為正式五關 stage 內容，並把目前 `ai-track-*` 內的題目與測資併入各自對應的 stage。

需要更新的檔案：

- `assets/game_content/challenges/challenge-group-*.yaml` 或之後重命名後的 stage challenge 檔
- route step 內對 level / challenge 的內容綁定

預期結果：

- 五關主地圖開始承載正式內容。
- 每一個地圖 stage 會打開該 stage 自己的正式題組，而不是直接依賴 `ai-track-*` 命名。
- 每一個地圖 stage 完成後，都會把該 stage 對應的新五關題目與測資，接到各自正式題組的第 1 題入口。
- 當正式五關內容穩定後，`ai-track-*` 可作為過渡檔案逐步移除。

### Phase 3：命名收斂

等五關 runtime 穩定之後，再視需要調整 legacy 命名。

例如：

- `group-01` -> `stage-01`
- `challenge-group-01-practice` -> 更貼近 stage 的命名

這一步應延後，不要與五關導入同時進行。

### Phase 4：清理過渡期殘留檔案

等五關主地圖與內容接線穩定後，移除為三關測試階段或過渡整合而保留的殘留檔案。

清理範圍包含：

- 已不再使用的舊 challenge / route / node 定義
- 僅供三關測試流程使用的 placeholder 內容
- 已被正式五關內容取代的過渡腳本或地圖資產
- 其他會造成 ownership 混淆的 legacy 檔案

這一步必須在主流程驗證完成後才執行，不應提前刪除仍參與 runtime 的檔案。

## 6. 檔案層級工作清單

### 6.1 Quest 層

`assets/game_content/quests/quest-main-map.yaml`

- 將 node list 從三關擴充為五關。
- 更新 completion node，改為第五關終點。

### 6.2 Node 層

`assets/game_content/nodes/main-map-nodes.yaml`

- 補上 stage 04 與 stage 05 的 node chain。
- 維持目前 `story / demo / practice / result` 的 node 類型。
- 保持整體 prerequisite 為線性順序。

### 6.3 Route 層

`assets/game_content/map_routes/main-map-routes.yaml`

- 補上 stage 04 與 stage 05 的 route group。
- 更新 route title 與 level 綁定內容。
- 過渡期內不變更 route step schema。

### 6.4 Challenge 層

`assets/game_content/challenges/`

- 將每個 stage 的正式 challenge 內容，改為承載對應新五關題目與測資。
- 以 `ai-track-*` 作為內容來源，逐步將其題目、測資與順序資訊搬入正式五關 stage。
- 視實際需求決定每個 stage 是接單一 level 還是小型 bundle，但先不要更動 challenge schema。
- 當五個地圖 stage 建立完成後，將每個 stage 對應的新五關題目與測資接到各自正式題組的第 1 題入口。

### 6.5 Godot 主地圖投影層

`godot_poc/scripts/map/quest_map_mapper.gd`

- 移除只對三關有意義的假設。
- 補上 stage 04 與 stage 05 的標題、描述、解鎖資訊。
- 確保進度標籤在五關狀況下仍正確。

### 6.6 Godot 主地圖呈現層

- `godot_poc/scripts/map/quest_map_screen.gd`
- `godot_poc/scenes/quest_map_screen.tscn`
- `godot_poc/scripts/map/quest_map_stage.gd`

- 將目前三個 stage anchor / card 擴成五個。
- 保留現有 overlay 互動模型。
- 保留目前 story / demo / practice 的 signal 與入口方式。

### 6.7 收尾清理層

- 移除已不再使用的五關過渡檔案。
- 移除已被正式五關流程取代的 legacy map / challenge / content 定義。
- 清理會造成主流程 ownership 不清的殘留檔案。

## 7. 風險

### 7.1 低風險

- 在 quest / nodes / routes 中增加 stage 數量
- 調整地圖標題與 stage metadata
- 將 practice 內容改綁到新 level

### 7.2 中風險

- 主地圖場景由三個 stage anchor 改為五個
- route summary 與 progress 顯示規則調整
- 確保 coordinator 在五關下仍能正確導向 story / demo / practice

### 7.3 高風險

- 直接以 level-chain 取代 group-based runtime 骨架
- 讓 Godot 地圖投影脫離 `group_views`
- 在同一波移除 story / demo / practice 既有頁面契約

上述高風險項目明確不納入本計畫。

## 8. 驗收條件

本階段完成的判定標準如下：

- 主地圖可顯示五個可玩的 stage。
- route state 仍與現有 Godot map flow 相容。
- 每個 stage 能正確打開對應的正式五關內容。
- 主地圖 runtime ownership 沒有重複骨架。
- 目前穩定頁面仍可運作：
  - map
  - scene
  - demo
  - practice

## 9. 建議執行順序

1. 先把 quest、nodes、routes 從三關擴成五關。
2. 再更新 Godot 主地圖 UI 與 mapper，支援五個 stage anchor。
3. 把 `ai-track-*` 中的題目與測資逐步併入正式五關 stage，並接到各 stage 正式題組的第 1 題入口。
4. 驗證從 Stage 01 到 Stage 05 的完整流程。
5. 清理過渡期殘留檔案。
6. 等流程穩定後，再考慮命名收斂或更深層的架構整併。

## 10. 總結

最穩的路線是：

- 保留目前 group-based 的主地圖 runtime 骨架
- 先把它從三關擴成五關
- 再把 `ai-track-*` 中的新五關題目與測資併入正式五關內容

這樣可以避免把五關內容導入，變成一次主流程 runtime 重寫。

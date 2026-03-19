# Godot Stage Overlay Plan

- 文件版本：0.1
- 更新日期：2026-03-19
- 文件定位：定義主地圖上方的關卡控制浮頁（stage overlay）之目標體驗、當前落地範圍與實作順序

## 1. 背景

目前 Godot 主地圖已可顯示 group 節點、route step 狀態與基本 routing。

但以玩家體驗來看，主地圖仍缺一層「進入關卡前的控制頁」：

- 主地圖應只顯示 group / 關卡節點
- 練習關不應直接出現在主地圖上
- 玩家點入某個 group 後，應先有一個中介控制層，決定要進 demo 還是 practice

因此需要在 quest map 上方新增一個 `stage overlay`，作為地圖與實際內容頁之間的中介介面。

## 2. 問題定義

若沒有這個 overlay，現在會出現幾個問題：

- 地圖節點與實際可進內容之間缺少一層過渡
- `demo` 與 `practice` 雖然同屬一個 group，但使用者無法清楚理解這兩條入口
- 練習關是 5 關 bundle，但地圖本身不適合直接展開這 5 關
- 後續若要加入電池、練習 bundle 規則、關卡解鎖內容，會缺少一個自然承接的位置

## 3. 最終目標

最終體驗應如下：

1. 玩家在主地圖上只看到 `Group 01 / Group 02 / Group 03` 這類關卡節點
2. 玩家點擊某個 group 後，主地圖背景被弱化，中央浮出一個 stage overlay
3. overlay 內容包含：
   - 關卡主題
   - 關卡描述
   - 本階段會解鎖的新積木圖示 / 卡片
   - `開始`
   - `練習`
4. `開始` 代表進入 demo 流程
5. `練習` 代表進入 practice bundle
6. practice 在資料上是 5 關綁定的一組，不在主地圖上拆成 5 個節點

## 4. 當前目標

本輪不追求最終視覺與完整規則，只先完成最小可用版本。

本輪要做到：

- 點 group card 時，不再直接切到 group-route preview scene
- 改成在 quest map 畫面上打開一個中央 overlay panel
- overlay 顯示：
  - 關卡標題
  - 簡短描述
  - 幾張 placeholder 的積木卡片
  - `開始` 按鈕
  - `練習` 按鈕
  - `關閉` 按鈕(右上角)
- `開始` 先接到 demo slot
- `練習` 先接到 practice slot
- `關閉` 回到主地圖

本輪暫不處理：

- 背景模糊特效
- 正式積木 icon / 美術表現
- 電池系統
- 練習 5 關的單題展開頁
- 完整的 bundle 規則 UI

## 5. 核心互動流程

### 5.1 主地圖到 overlay

1. 玩家點擊主地圖上的某個 group
2. 若 group 尚未解鎖，仍停留在主地圖並提示 locked
3. 若 group 可進入，則在主地圖上方打開 overlay
4. overlay 預設聚焦在該 group 的基本資訊與兩個入口按鈕

### 5.2 Overlay 到 Demo

1. 玩家在 overlay 點擊 `開始`
2. 系統以該 group 的 `demo_slot` 作為入口
3. 若 demo 對應的 live state 已可直接開啟 scene / challenge，則進正式頁
4. 若尚不能直接開啟，則保留現有 fallback 提示或 preview 行為

### 5.3 Overlay 到 Practice

1. 玩家在 overlay 點擊 `練習`
2. 系統以該 group 的 `practice_slot` 作為入口
3. practice 在概念上是 bundle，而不是單題節點
4. 現階段先只需能從這個入口進到 practice 流程
5. 後續再補 `x / 5`、單題清單、電池消耗等資訊

## 6. 資料需求

為了支撐 overlay，group view 至少需要補以下欄位：

- `theme_title`
  - 關卡主題
- `theme_description`
  - 關卡描述
- `unlock_blocks`
  - 本階段新解鎖積木資料
  - 現階段可先用 placeholder card 表示
- `demo_slot`
  - 現有資料模型已存在
- `practice_slot`
  - 現有資料模型已存在

### 6.1 `unlock_blocks` 最小格式

建議先用最小卡片資料：

```yaml
unlock_blocks:
  - block_id: print
    title: print
    description: 輸出文字到畫面
  - block_id: input
    title: input
    description: 讀取玩家輸入
```

這一層現階段可先由 Godot mapper 組 placeholder，未來再正式搬回 content。

## 7. UI 結構

建議 UI 採以下階層：

- `QuestMapScreen`
  - 既有主地圖內容
  - `StageOverlay`
    - 半透明底層
    - 中央 panel
      - 關卡主題
      - 關卡描述
      - unlock block cards
      - `開始`
      - `練習`
      - `關閉`

### 7.1 現階段視覺要求

- overlay 出現在畫面中央
- 主地圖仍可見，但被視覺上弱化
- 解鎖積木先用簡單卡片呈現
- 不要求動畫與最終美術

## 8. 與目前資料模型的關係

目前 group 已拆成：

- `demo_slot`
- `practice_slot`
- `practice_levels`

因此這個 overlay 不需要重新發明資料結構，而是：

- 直接消費 group view
- 用 `demo_slot` 決定 `開始` 按鈕行為
- 用 `practice_slot` 決定 `練習` 按鈕行為
- 後續可再利用 `practice_levels` 顯示 `Practice 1~5`

## 9. 實作順序

### Step 1. 補 overlay 所需 view model

目標：讓 group view 能提供 overlay 所需資料。

至少包含：

- `theme_title`
- `theme_description`
- `unlock_blocks`
- `demo_slot`
- `practice_slot`

### Step 2. 在 QuestMapScreen 上新增 overlay panel

目標：建立可顯示 / 關閉的中央浮頁。

驗收：

- 可從 group click 打開
- 可關閉並回到主地圖
- 不切換到其他 scene page

### Step 3. 把 group click 從 preview 改成 overlay

目標：取消現在的 group-route preview 主要入口角色。

驗收：

- 點 group 時優先打開 overlay
- 不再先跳到 scene preview page

### Step 4. 接上 `開始` / `練習`

目標：讓 overlay 成為真正的入口分流層。

驗收：

- `開始` 走 demo
- `練習` 走 practice

### Step 5. 補最小狀態文案

目標：讓 overlay 不只是兩個按鈕，而是有基本導引資訊。

驗收：

- 能看出該 group 主題
- 能看出這一階段學什麼
- 能知道 `開始` 與 `練習` 的差異

## 10. 後續擴充點

這份 overlay 計畫之後可自然擴充為：

- 練習 bundle `x / 5` 進度顯示
- practice 單題展開清單
- 電池消耗規則
- Replay demo / Retry practice
- 背景模糊與正式動畫
- 正式積木 icon / 美術卡片

## 11. 本文件結論

這個 stage overlay 的目的，不是新增一個獨立大頁面，而是：

- 保持主地圖只顯示關卡節點
- 在進入 group 後提供一個自然的中介控制層
- 把 `demo` 與 `practice bundle` 分流乾淨
- 為之後的練習進度與電池規則預留位置

現階段先做簡易浮頁版本即可，只要能成功從 group 打開 overlay，並從 overlay 進 `demo` 與 `practice`，就算完成第一步。

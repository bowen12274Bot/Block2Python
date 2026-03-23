# Godot 畫面設定調整教學

- 文件版本：0.1.0
- 更新日期：2026-03-21
- 適用範圍：`godot_poc/` 內的 Godot 畫面調整，特別是進入頁 `entry_screen.tscn`

## 1. 這份文件要解決什麼

這份文件不是 Godot 通識課，而是說明在本專案裡如何安全地調整畫面，讓美術素材、場景結構、互動邏輯能一起工作。

你可以用這份文件回答這幾個問題：

- 我應該在哪個 scene 裡調整畫面
- 哪些節點是放素材用的 slot
- 哪些東西可以直接手拉
- 哪些東西在 `Container` 裡，不能只靠拖曳調整
- 我要怎麼在 Godot 中掛背景圖、角色圖、裝飾圖
- 改完之後怎麼確認沒有把互動流程弄壞

## 2. 目前最適合開始調整的場景

目前最適合拿來做畫面調整的是：

- [entry_screen.tscn](/e:/bowen.code/project/Block2Python/godot_poc/scenes/entry_screen.tscn)

原因：

- 這個場景已經整理成可放素材的畫面骨架
- 建角流程已經接好，不是假的靜態頁
- 已預留背景、裝飾、角色卡、輸入區、按鈕區
- 比主地圖、劇情頁更容易先建立視覺方向

## 3. 進入頁目前的結構

`entry_screen.tscn` 目前主要分成這幾層：

- `BackgroundLayer`
- `DecorLayer`
- `ContentLayer`
- `OverlayLayer`

### 3.1 BackgroundLayer

用途：背景底圖與底色。

目前包含：

- `BackgroundFill`
  - 純色底。沒背景圖時，畫面至少不會全空。
- `BackgroundTexture`
  - 可直接掛背景圖。
- `BackgroundAccent`
  - 中央偏亮的色塊，可保留，也可之後視覺調整時移除或換素材。

### 3.2 DecorLayer

用途：非必要互動的裝飾物。

目前包含：

- `LeftDecorSlot`
- `RightDecorSlot`
- `TopGlowSlot`

這些都是 `TextureRect`，可以直接掛圖。

### 3.3 ContentLayer

用途：玩家主要會看到與操作的內容。

目前包含：

- `HeaderLayer`
- `CharacterSelectLayer`
- `NameInputLayer`
- `ActionLayer`
- `StatusLayer`

角色卡相關節點在這裡：

- `MaleCard`
  - `MaleArtSlot`
  - `MaleSelectionGlow`
  - `MaleButton`
- `FemaleCard`
  - `FemaleArtSlot`
  - `FemaleSelectionGlow`
  - `FemaleButton`

### 3.4 OverlayLayer

用途：最上層的覆蓋 UI。

目前主要放開發用控制：

- `DeveloperLayer`
  - `StartBridgeButton`
  - `ResetButton`

這一塊偏開發期用途，正式版可以改位置、隱藏，或之後拆掉。

## 4. 在 Godot 裡如何載入素材

最常用的做法是把素材掛到 `TextureRect`。

### 4.1 建議素材路徑

可以先在專案裡建立這類資料夾：

- `godot_poc/assets/art/backgrounds/`
- `godot_poc/assets/art/characters/`
- `godot_poc/assets/art/decor/`
- `godot_poc/assets/art/ui/`

### 4.2 載入步驟

1. 把圖片檔放進上述資料夾。
2. 打開 Godot editor。
3. 打開 [entry_screen.tscn](/e:/bowen.code/project/Block2Python/godot_poc/scenes/entry_screen.tscn)。
4. 在 Scene tree 選擇要放圖的節點，例如 `MaleArtSlot`。
5. 在右側 Inspector 找 `Texture`。
6. 把圖片拖進 `Texture` 欄位，或點選檔案指定。
7. 視需要調整節點大小、位置與 `Stretch Mode`。

### 4.3 目前可直接掛圖的節點

- `BackgroundTexture`
- `LeftDecorSlot`
- `RightDecorSlot`
- `TopGlowSlot`
- `MaleArtSlot`
- `FemaleArtSlot`

## 5. 哪些東西可以直接手動調整

這些通常適合直接在 Godot editor 內手調：

- 背景圖位置
- 裝飾圖位置
- 左右裝飾圖大小
- 背景圖裁切效果
- 標題、副標之間的視覺留白
- 角色圖在卡片中的構圖
- 按鈕視覺位置
- 裝飾元素是否偏左、偏右、偏上

這些調整屬於「看畫面感覺」的工作，直接手調通常比較快。

## 6. 哪些東西不要只靠拖曳

如果節點在 `VBoxContainer`、`HBoxContainer`、`MarginContainer`、`CenterContainer` 裡，很多尺寸不是靠拖曳決定，而是靠 layout 規則決定。

這種情況下，應優先調整：

- `custom_minimum_size`
- `theme_override_constants/separation`
- `theme_override_constants/margin_*`
- `size_flags_horizontal`
- `size_flags_vertical`

### 6.1 常見例子

如果你覺得進入頁整體太高，不要先硬拉最裡面的節點，請先看：

- `ContentStack`
  - 調整區塊之間的 `separation`
- `MaleCard` / `FemaleCard`
  - 調整 `custom_minimum_size`
- `MaleArtSlot` / `FemaleArtSlot`
  - 調整圖片區的高度
- `StatusMargin`
  - 調整狀態區上下左右留白
- `CreateButton`
  - 調整按鈕高度

## 7. 手調與結構設定的分工

### 7.1 適合手調

- 背景構圖
- 裝飾位置
- 角色圖視覺重心
- 版面看起來是否太空或太擠
- 哪個區塊要再上移或下移一些

### 7.2 適合用結構規則控制

- 整頁安全邊界
- 主要區塊之間的固定間距
- 卡片最小尺寸
- 輸入框與按鈕的可點擊高度
- 在不同視窗大小下是否容易跑版

簡單說：

- 視覺結果靠手調
- 穩定版面靠 layout 規則

## 8. 為什麼有些節點拖不動

最常見原因不是 Godot 壞掉，而是該節點被父 `Container` 管理。

例如：

- `ContentStack` 是 `VBoxContainer`
- `CharacterRow` 是 `HBoxContainer`
- `MaleCardRoot` / `FemaleCardRoot` 是 `VBoxContainer`

在這種結構下：

- 子節點的位置很多時候不能直接自由拖曳
- 你看到的高度常常是 container 算出來的
- 拖曳沒反應時，通常要回頭改 `custom_minimum_size` 或 `separation`

## 9. 角色卡怎麼調整

目前角色卡是：

- `MaleCard`
- `FemaleCard`

每張卡都包含：

- `ArtSlot`
- `SelectionGlow`
- `Button`

建議調整順序：

1. 先決定角色圖大概是頭像卡還是半身卡。
2. 再調 `MaleArtSlot` / `FemaleArtSlot` 高度。
3. 確認卡片整體高度是否合理。
4. 最後再調整卡片之間的間距與位置。

如果暫時不確定，先用比較高的半身卡骨架通常比較安全，之後往下縮比反過來容易。

## 10. 進入頁目前的基本互動

互動邏輯在 [entry_screen.gd](/e:/bowen.code/project/Block2Python/godot_poc/scripts/entry/entry_screen.gd)。

目前已接好的包含：

- `Start Bridge`
- `Reset`
- `Create Character`
- 男 / 女選擇
- 卡片選中高亮

你調整畫面時，盡量不要改掉這些節點名稱，否則 script 路徑會失效。

特別要注意這些節點名稱目前有被 script 使用：

- `StartBridgeButton`
- `ResetButton`
- `NameInput`
- `MaleCard`
- `FemaleCard`
- `MaleSelectionGlow`
- `FemaleSelectionGlow`
- `MaleButton`
- `FemaleButton`
- `CreateButton`
- `SummaryLabel`
- `StatusLabel`

## 11. 實際建議操作順序

第一次調整進入頁時，建議依序做：

1. 打開 [entry_screen.tscn](/e:/bowen.code/project/Block2Python/godot_poc/scenes/entry_screen.tscn)。
2. 先確認 `BackgroundFill` 的純色底是否可接受。
3. 如果有背景圖，掛到 `BackgroundTexture`。
4. 把左右裝飾圖掛到 `LeftDecorSlot` / `RightDecorSlot`。
5. 把角色圖掛到 `MaleArtSlot` / `FemaleArtSlot`。
6. 微調角色卡高度與間距。
7. 微調標題、名稱輸入框、主按鈕位置。
8. Play scene 檢查是否仍可選角色、輸入名字、按建立角色。

## 12. 修改後怎麼驗證沒有壞

至少做這些：

1. 打開 Godot，進入 `game_flow_root.tscn`。
2. 進入 entry page。
3. 確認畫面沒有元素完全跑出可視區。
4. 點選男 / 女，確認高亮正常。
5. 輸入名稱。
6. 按 `Create Character`，確認流程仍能繼續。
7. 如果有掛大圖，確認沒有擋住按鈕點擊。

## 13. 常見問題

### 13.1 素材掛上去但看起來變形

先檢查：

- `TextureRect` 的 `Stretch Mode`
- 該節點的寬高比
- 圖片本身比例

### 13.2 我改了裝飾圖，按鈕變得點不到

通常是上層裝飾節點攔了滑鼠事件。檢查該節點是否應設為不處理滑鼠事件。

### 13.3 我想拉高卡片，但整頁被往下撐爆

代表它在 container 結構裡。應回頭調整：

- 卡片 `custom_minimum_size`
- 圖片 slot 高度
- 區塊 `separation`
- 外框 `margin`

而不是只拉單一子節點。

## 14. 後續可延伸

當 entry page 調整方法成熟後，可以把同樣概念套到：

- `quest_map_screen.tscn`
- `scene_flow_screen.tscn`
- `challenge_screen.tscn`

但目前仍建議先以進入頁做第一個完整範例。
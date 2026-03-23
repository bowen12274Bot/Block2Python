# Toolbox 視窗對位修復指南

- 文件版本：0.1.0
- 更新日期：2026-03-23
- 適用範圍：`godot_poc/` 練習頁外部工具視窗嵌入，特別是 `PySide6` toolbox 疊在 Godot practice editor 上的場景

## 1. 這份文件要解決什麼

這份文件記錄的是一個很容易反覆踩坑的問題：

- Godot 內部有一塊 editor 區
- 外部 `PySide6` 工具視窗要貼在它上面
- 視窗切換大小、拖動、DPI 縮放後仍要維持對位

這不是單純調幾個 offset 就能解決的事情，因為中間會經過：

- Godot viewport 座標
- Godot stretch / letterbox 換算
- Windows client area 座標
- Qt / Win32 視窗定位座標

這份文件的目標是讓之後再做工具包、AI 面板、外部編輯器等嵌入時，不用再從頭調一次。

## 2. 最後確認過的根因

這次問題不是單一 bug，而是幾個小問題疊在一起：

1. Godot 端一開始手抄畫面縮放公式，和實際 `canvas_items + keep` 的行為不完全一致。
2. 對位目標曾經拿錯層級，先後試過 `PracticePanel`、`ToolboxAnchor`，最後才確認應該對齊 `code_input` 這類有實際尺寸的 control。
3. `ToolboxAnchor` 一度設成 `visible=false` 且沒尺寸，導致目標矩形變成 `0x0`。
4. 最大問題是 DPI 座標系不一致：
   - Win32 `ClientToScreen()` 回的是實體像素
   - Qt `QWidget.move()` 在高 DPI 下吃的是邏輯像素
   - 結果就是 Godot 視窗越移，toolbox 越歪
5. 外部視窗定位最後若不走 Win32 API，而只靠 Qt `move()`，在 Windows 縮放下很容易再次漂移。

## 3. 最終採用的修法

最後穩定的方案是：

1. Godot 端只負責算出 editor 在「Godot client area」裡的位置與大小。
2. 這個矩形必須用實際的 editor control 來量，不要用沒有尺寸的 placeholder。
3. Godot 將矩形寫入 toolbox layout 檔。
4. PySide toolbox 讀到 layout 後，用 Win32 `ClientToScreen()` 取得 Godot 主視窗 client origin。
5. 再用 Win32 `SetWindowPos()` 把 toolbox 放到正確桌面座標。

也就是：

```text
Godot editor rect
-> client-area rect
-> layout json
-> Win32 client origin
-> SetWindowPos() desktop placement
```

## 4. 這次實作中真正有效的關鍵

### 4.1 對齊目標要用有實際尺寸的 control

最後使用的是：

- [practice_panel.gd](/e:/bowen.code/project/Block2Python/godot_poc/scripts/game_flow/practice_panel.gd)
  - `code_input.get_global_rect()`

不要假設：

- 父 panel 的矩形就等於 editor 工作區
- 一個透明 placeholder 一定有尺寸

如果未來要對齊別的區塊，優先找：

- 真的會顯示的 control
- 有固定 layout 的 control
- `get_global_rect()` 有穩定數值的 control

### 4.2 Godot stretch 換算要用 uniform scale

這個專案目前的關鍵設定是：

- [project.godot](/e:/bowen.code/project/Block2Python/godot_poc/project.godot)
  - `display/window/size/viewport_width = 1200`
  - `display/window/size/viewport_height = 720`
  - `display/window/stretch/mode = "canvas_items"`
  - `display/window/stretch/aspect = "keep"`
  - `display/window/dpi/allow_hidpi = true`

在這組設定下，Godot 畫面不是獨立 X/Y 縮放，而是：

```text
uniform_scale = min(client_width / viewport_width, client_height / viewport_height)
used_size = viewport_size * uniform_scale
offset = (client_size - used_size) / 2
```

最後 editor client-area 座標要用：

```text
screen_x = offset.x + global_rect.position.x * uniform_scale
screen_y = offset.y + global_rect.position.y * uniform_scale
screen_width = global_rect.size.x * uniform_scale
screen_height = global_rect.size.y * uniform_scale
```

這份邏輯已經落在：

- [practice_panel.gd](/e:/bowen.code/project/Block2Python/godot_poc/scripts/game_flow/practice_panel.gd)

### 4.3 不要再用 Qt `move()` 當最終定位

這次最難抓的點就是：

- Win32 client origin 是實體像素
- Qt `move()` 在高 DPI 下不是同一套像素

結果會出現：

- 一開始看起來差不多
- 視窗越往右拖越歪
- 模式切換後偏移不同

最後穩定修法是：

- [window.py](/e:/bowen.code/project/Block2Python/src/block2python/clients/toolbox_window/window.py)
  - 優先走 Win32 `SetWindowPos()`
  - 不再把 Qt `move()` 當成主要定位手段

## 5. 三個關鍵檔案各自負責什麼

### 5.1 `practice_panel.gd`

責任：

- 算 editor 在 Godot client area 內的矩形
- 不直接碰外部桌面座標

現在輸出的欄位：

- `x`, `y`
- `width`, `height`
- `screen_x`, `screen_y`
- `screen_width`, `screen_height`
- `visible`

### 5.2 `game_flow_coordinator.gd`

責任：

- 把 editor rect 包成 toolbox layout payload
- 帶上 `owner_title` 與 `owner_hwnd`
- 持續同步 layout 檔給外部 toolbox

對位資訊是在：

- [game_flow_coordinator.gd](/e:/bowen.code/project/Block2Python/godot_poc/scripts/flow/game_flow_coordinator.gd)
  - `_sync_toolbox_layout_file()`

### 5.3 `window.py`

責任：

- 讀 layout json
- 找到 Godot 主視窗 client origin
- 用 Win32 `SetWindowPos()` 進行真正定位

核心流程在：

- [window.py](/e:/bowen.code/project/Block2Python/src/block2python/clients/toolbox_window/window.py)
  - `_resolve_client_origin_from_hwnd()`
  - `_refresh_layout()`

## 6. 之後再做外部工具嵌入時的標準流程

如果之後還要嵌：

- 另一個 block editor
- AI 助教浮動視窗
- 外部 Python 工具視窗
- 自訂 inspector / diagnostics panel

請直接照這個流程做：

1. 在 Godot 內找一個「真實有尺寸」的 control 當對齊目標。
2. 用 `get_global_rect()` 取得該 control 在 viewport 內的矩形。
3. 用 `uniform scale + letterbox offset` 換成 client-area 座標。
4. 將這個矩形寫進 layout 檔，不要在 Godot 端猜桌面絕對座標。
5. 外部視窗端用 Win32 找 Godot `HWND` 的 client origin。
6. 最終用 Win32 `SetWindowPos()` 定位，不要只用 Qt `move()`。

## 7. 不要再重踩的坑

以下做法未來不要再走：

- 不要靠手調固定 offset 當主要解法。
- 不要用 `visible=false` 且沒尺寸的 anchor 當對位目標。
- 不要把 `get_screen_transform()` 直接當桌面絕對座標。
- 不要同時混用 Qt 邏輯像素與 Win32 實體像素，卻假設它們等價。
- 不要把「看起來差不多」當成對位成功，要驗證拖動主視窗後是否仍穩定。

## 8. 驗證 checklist

每次改 toolbox 對位相關程式後，至少檢查：

1. 開 toolbox 時是否貼到 editor 上方。
2. Godot 視窗在 windowed 模式拖動時，toolbox 是否仍維持對位。
3. 最大化 / 還原後是否仍維持對位。
4. 不同 DPI 或縮放設定下是否沒有明顯漂移。
5. toolbox 關閉後，practice screen 是否正確解除鎖定。
6. `Run` 在 toolbox 開啟時，是否仍走 block workspace。

## 9. 建議保留的專案設定與假設

如果未來沒有特殊理由，請保留：

- `viewport = 1200 x 720`
- `stretch mode = canvas_items`
- `aspect = keep`
- `allow_hidpi = true`

如果這些設定改了，請預期：

- `practice_panel.gd` 的矩形換算要重新驗證
- 外部視窗對位可能要重新校準

## 10. 一句話總結

這次修好的重點不是某個神奇偏移值，而是把三件事分清楚：

- Godot 內要蓋哪個 control
- Godot client area 內座標怎麼算
- 外部 Win32 視窗要怎麼用同一套像素系統定位

只要這三件事保持分層，之後再嵌新的外部工具窗，就不需要再重打一遍這場仗。

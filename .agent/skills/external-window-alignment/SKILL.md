---
name: external-window-alignment
description: 處理 Block2Python 中 Godot 畫面與外部 PySide6 / Win32 工具視窗的對位、嵌入與 DPI 問題。用於新增或修改 toolbox、AI 助教窗、外部 inspector、Blockly 視窗等外部工具窗，特別是涉及 target control 選擇、canvas_items + keep stretch 換算、layout json、owner_hwnd、ClientToScreen、SetWindowPos 與 Windows-only 對位邏輯時。
---

# External Window Alignment

使用此 skill 處理 Block2Python 中「Godot 內部 control 與外部工具視窗」的對位工作。

這個 skill 的目標不是一般 UI 排版，而是處理下列問題：

- Godot 某個 editor / panel 要被外部 PySide6 視窗覆蓋
- 對位在 windowed / maximized / DPI 縮放下仍要穩定
- 需要把 Godot 的 client-area rect 正確轉成 Win32 桌面座標

## 範圍

- 抽象或修改 Godot 端 target control 的對位輸出
- 維護 layout json 的 payload 形狀與同步流程
- 維護 PySide6 / Win32 對位邏輯，例如 `ClientToScreen` 與 `SetWindowPos`
- 整理「之後新增其他外部工具窗時」可重用的對位流程

不適用於：

- 純 Godot 內部 panel 疊放
- 一般 practice / scene 畫面視覺排版
- 與外部視窗對位無關的 bridge 或 gameplay 邏輯

## 先讀

先讀這份主文件：

- [`docs/contributing/toolbox_window_alignment_guide.md`](../../../docs/contributing/toolbox_window_alignment_guide.md)

視需求再看這幾個實作入口：

- Godot 對位 helper：[`godot_poc/scripts/bridge/window_alignment.gd`](../../../godot_poc/scripts/bridge/window_alignment.gd)
- Godot layout sync：[`godot_poc/scripts/bridge/window_layout_sync.gd`](../../../godot_poc/scripts/bridge/window_layout_sync.gd)
- 練習頁 target provider：[`godot_poc/scripts/game_flow/practice_panel.gd`](../../../godot_poc/scripts/game_flow/practice_panel.gd)
- coordinator 對位接線：[`godot_poc/scripts/flow/game_flow_coordinator.gd`](../../../godot_poc/scripts/flow/game_flow_coordinator.gd)
- PySide Win32 helper：[`src/block2python/clients/pyside6/window_alignment.py`](../../../src/block2python/clients/pyside6/window_alignment.py)
- toolbox 視窗：[`src/block2python/clients/toolbox_window/window.py`](../../../src/block2python/clients/toolbox_window/window.py)

## 操作指引

1. 先選對 target control。
   - 優先用有實際尺寸、穩定 layout 的 `Control`
   - 不要用 `visible=false` 且沒尺寸的 placeholder
   - 不要先猜父 panel 是否等於真正 editor 區

2. Godot 端只算 client-area rect。
   - 用 `get_global_rect()` 取 viewport 內矩形
   - 用 `canvas_items + keep` 的 `uniform scale + letterbox offset` 轉成 client-area rect
   - 不要在 Godot 端直接猜桌面絕對座標

3. layout payload 只承載對位資料。
   - 保持 `level_id / owner_title / owner_hwnd / relative_* / screen_* / visible`
   - 若只是新增另一個外部工具窗，優先沿用同一份 payload contract

4. 外部視窗端統一負責桌面定位。
   - 先用 `owner_hwnd` 或 `owner_title` 找主視窗 client origin
   - 再組出最終 target rect
   - 在 Windows 上用 `SetWindowPos()`，不要把 Qt `move()` 當主要定位手段

5. 若要擴到其他 screen。
   - 在對應 screen / panel 提供 `get_<tool>_target_control()` 或等價 target provider
   - 盡量重用既有 alignment helper，不要把縮放數學複製到新檔案

## 固定規則

- 第一版預設只支援 Windows。
- `screen_*` 在這個專案語意上是 client-area-scaled rect，不是最終桌面絕對座標。
- 真正的桌面定位轉換，一律放在 PySide / Win32 helper。
- 若 `project.godot` 的 viewport、stretch mode、aspect、hidpi 設定改了，必須重新驗證對位。

## 不要再踩的坑

- 不要靠手調 offset 當主要解法。
- 不要混用 Qt 邏輯像素與 Win32 實體像素，卻假設兩者等價。
- 不要把 `get_screen_transform()` 直接當成桌面絕對座標。
- 不要在不同 screen 複製一份 stretch 換算數學。
- 不要看到「大概對」就收工，一定要驗證拖動主視窗後是否仍穩定。

## 驗證

最小自動驗證：

```powershell
pytest -o addopts= tests/test_toolbox_window_main.py tests/test_window_alignment.py
```

最小人工驗證：

1. 開啟 practice 頁與 toolbox。
2. 確認 toolbox 貼在 editor 區上。
3. 拖動 Godot 主視窗，確認 toolbox 不累積偏移。
4. 測 windowed / maximized。
5. 關閉 toolbox，確認 practice screen 正常解鎖。

## 何時更新這個 skill

當以下任一情況發生時，應更新這個 skill：

- layout payload contract 改變
- Godot stretch / viewport 設定改變
- 對位 helper 被搬移或重命名
- 外部工具窗從 toolbox 擴展到更多 PySide6 視窗
- Windows-only 假設被打破，開始加入跨平台 fallback

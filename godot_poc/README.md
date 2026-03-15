# Godot POC

這是 Block2Python `stdio bridge` 的最小 Godot 概念驗證 client。

目前範圍：

- 啟動 Python bridge process
- 送出 `reset`
- 讀取一筆 JSON response
- 顯示 `GameState` 的部分欄位

## 前置需求

- Godot 4.x
- Windows
- repo 的 virtualenv 存在於 `../.venv/Scripts/python.exe`

## 執行方式

1. 用 Godot 4.x 開啟 `godot_poc/project.godot`
2. 執行主場景
3. 點擊 `Start Bridge`
4. 點擊 `Reset`

預期結果：

- 狀態列變成 `Bridge running`
- response 區塊顯示 `ok = true`
- state 區塊顯示初始的 `mode`、`node_id`、`node_title`

## 備註

- 這是一個 POC client，不是最終的 Godot 前端
- bridge process 會以 `PYTHONPATH=../src` 啟動
- bridge server 會明確帶入 `--levels-dir` 與 `--game-content-dir`
  參數，讓 Godot 專案不需要放在 repo root 也能執行
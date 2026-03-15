# Godot Bridge Client Guide v0.1

- 版本：`0.1`
- 日期：`2026-03-14`
- 狀態：未來 client 接入說明

## 1. 目的

本文件說明未來 Godot client 應如何接入目前的 Python stdio bridge。

這份文件是 client integration guide，不是協定的正式來源。
協定本身定義在：

- `docs/specs/bridge_stdio_protocol_v0_1.md`

## 2. 啟動流程

### 2.1 啟動 bridge process

Godot 應先啟動一個長駐的 Python subprocess：

```text
python -m block2python.integration.bridge_stdio.server
```

啟動後，Godot 應只透過這個 process 的 `stdin/stdout` 與 Python 溝通。

### 2.2 重設到初始狀態

如果 Godot 想從乾淨的 quest 起點開始，可先送出：

```json
{
  "command": "reset"
}
```

收到 response 後，應把回傳的 `state` 視為正式初始狀態。

## 3. Scene Flow 範例

當玩家按下「下一步」時，Godot 應送出：

```json
{
  "action": {
    "action_type": "advance",
    "payload": {}
  }
}
```

收到新的 `GameState` 後：

- 若 `mode = scene`
  - 更新 scene UI
  - render `scene.dialogue_blocks`
- 若 `mode = challenge`
  - 切換到 challenge UI
  - render `challenge.current_level_id`
  - 根據 `available_actions.submit` 決定是否開啟提交 UI

## 4. Submit Flow 範例

當玩家提交程式碼時，Godot 應送出：

```json
{
  "action": {
    "action_type": "submit_level",
    "payload": {
      "python_code": "print(3)\n",
      "block_json": {
        "kind": "workspace"
      }
    }
  }
}
```

收到新的 `GameState` 後，Godot 應優先檢查：

- `last_submission`
- `mode`
- `challenge`
- `progress`

常見處理方式：

- 如果 `last_submission.judge_status = "AC"`
  - 顯示過關回饋
- 如果 `last_submission.judge_status = "WA"`
  - 顯示失敗回饋與摘要
- 如果 `progress.cleared_level_ids` 增加
  - 更新進度 UI
- 如果 `challenge.current_level_id` 改變
  - 切換到下一關 UI

## 5. 錯誤處理

如果 bridge 回傳：

```json
{
  "ok": false,
  "state": null,
  "error": "..."
}
```

Godot 應：

- 保留目前 UI 狀態
- 顯示錯誤訊息
- 允許玩家重試或重新同步

當 `ok = false` 時，Godot 不應假設狀態已更新。

## 6. 建議的 Godot 責任分工

Godot 端建議拆成以下責任：

- Bridge Client
  - 啟動並管理 Python subprocess
  - 寫入 JSON request
  - 讀取 JSON response
- State Mapper
  - 將 `GameState` 轉為 Godot 側的 UI/state model
- Scene Renderer
  - 根據 `mode`、`scene`、`challenge` 切換畫面
- Input Adapter
  - 將玩家輸入轉成 `PlayerAction`

## 7. 核心原則

Godot 端應遵守以下原則：

- 不直接 import Python 內部模組
- 不在 Godot 端推進 quest/node 規則
- 不在 Godot 端判定 challenge 成敗
- 只送 `PlayerAction`
- 只根據 `GameState` 更新畫面

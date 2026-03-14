# Bridge Stdio 協定 v0.1

- 版本：`0.1`
- 日期：`2026-03-14`
- 狀態：已在 Python bridge MVP 中實作

## 1. 目的

本文件定義目前 `stdin/stdout JSON` 橋接介面的協定，實作位置在：

- [server.py](/e:/bowen.code/project/Block2Python/src/block2python/integration/bridge_stdio/server.py)

這份協定的目的是提供一條穩定的外部傳輸邊界，讓下列 client 可以接入：

- 未來的 Godot 前端
- CLI smoke 工具
- 其他本機 client adapter

本協定不定義遊戲規則本身，只定義：

- request envelope
- response envelope
- 支援的 command
- 支援的 `PlayerAction`
- `GameState` 回傳格式

## 2. 傳輸方式

- 輸入：`stdin` 每行一個 JSON 物件
- 輸出：`stdout` 每行一個 JSON 物件
- 編碼：UTF-8 JSON
- session 模式：單一 bridge process 內維持狀態

這代表一個長駐 bridge process 會持有一份記憶體中的 `GameSession`。

## 3. Request Envelope

每個 request 都必須是 JSON 物件。

目前支援兩種 request 形式。

### 3.1 Action request

```json
{
  "action": {
    "action_type": "advance",
    "payload": {}
  }
}
```

### 3.2 Reset request

```json
{
  "command": "reset"
}
```

`reset` 會把目前記憶體中的 session 重建回 quest 起始狀態。

## 4. Response Envelope

所有 response 都使用同一個外層格式：

```json
{
  "ok": true,
  "state": {},
  "error": null
}
```

失敗時則為：

```json
{
  "ok": false,
  "state": null,
  "error": "error message"
}
```

規則如下：

- `ok = true` 時，`state` 一定存在，`error = null`
- `ok = false` 時，`state = null`，`error` 會放人類可讀的錯誤訊息

## 5. 支援的 PlayerAction

### 5.1 `advance`

```json
{
  "action": {
    "action_type": "advance",
    "payload": {}
  }
}
```

行為：

- 在目前狀態允許時，推進 scene flow
- 回傳新的 `GameState`

### 5.2 `submit_level`

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

payload 欄位：

- `python_code: str` 必填
- `block_json: dict | null` 選填

行為：

- 透過 `GameSession` 提交目前 challenge level
- 回傳新的 `GameState`
- 提交結果會附加在 `GameState.last_submission`

### 5.3 `restart_quest`

這個 action 名稱已存在於 contract，但目前尚未實作。

目前行為：

- response 會回傳 `ok = false`
- `error = "restart_quest is not implemented"`

## 6. GameState 格式

目前 `GameState` 欄位如下：

```json
{
  "mode": "scene",
  "quest_id": "quest-basic-io-repair",
  "node_id": "story-intro",
  "node_title": "City Alarm",
  "scene": {
    "scene_id": "scene-city-alarm",
    "title": "City Alarm",
    "dialogue_blocks": [
      {
        "speaker": "Byte",
        "text": "The city alarm is broken.",
        "portrait_id": "byte-default",
        "expression": "alert",
        "emphasis": "normal"
      }
    ]
  },
  "challenge": null,
  "progress": {
    "completed_node_ids": ["map-entry"],
    "cleared_level_ids": []
  },
  "available_actions": {
    "advance": true,
    "submit": false,
    "restart_quest": false
  },
  "last_submission": null,
  "errors": []
}
```

欄位說明：

- `mode`
  - 可能值為 `scene`、`challenge`、`complete`
- `scene`
  - 當前應顯示 scene 時會存在
- `challenge`
  - 當前 node 掛有 challenge group 時會存在
- `available_actions`
  - client 應把它視為目前可操作行為的正式依據
- `last_submission`
  - 最近一次 `submit_level` 的提交結果

## 7. 提交結果格式

成功執行 `submit_level` 後，`GameState.last_submission` 可能長這樣：

```json
{
  "level_id": "demo-1",
  "cleared": true,
  "block_passed": true,
  "analysis_status": "PASS",
  "analysis_summary": "OK",
  "judge_status": "AC",
  "judge_summary": "Accepted"
}
```

這讓 client 可以直接顯示：

- analysis 結果
- judge 結果
- clear / fail 回饋

而不需要再另外發明一個獨立於 `GameState` 之外的提交結果 envelope。

## 8. 錯誤情況

常見錯誤 response 如下。

### 8.1 非法 JSON

```json
{
  "ok": false,
  "state": null,
  "error": "Invalid JSON: ..."
}
```

### 8.2 非法 action 格式

```json
{
  "ok": false,
  "state": null,
  "error": "PlayerAction.action_type must be a string"
}
```

### 8.3 非法遊戲操作

```json
{
  "ok": false,
  "state": null,
  "error": "Cannot advance a challenge node without clearing the current level"
}
```

## 9. 目前限制

- 一個 process 只持有一份記憶體內 session
- 尚未支援 persistent save/load
- `restart_quest` contract 已存在，但尚未實作
- 目前沒有事件流，只有完整 state snapshot
- 目前沒有 request id / correlation id

## 10. 下一步可能擴充

- 加入 request id / response id
- 加入明確的 save/load command
- 定義穩定的 Godot action 子集合
- 視需要擴充更完整的 challenge / judge 明細 payload

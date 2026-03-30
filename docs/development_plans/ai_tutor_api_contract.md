# AI Tutor API 契約（Phase 2）

- 文件版本：0.1
- 更新日期：2026-03-30
- 狀態：Phase 2 已實作（Bridge Stdio），HTTP Router 版本待補
- Source of truth：
  - `src/block2python/integration/bridge_stdio/server.py`
  - `src/block2python/integration/contracts/models.py`
  - `src/block2python/integration/contracts/serialize.py`

## 1. 目的與範圍

本文件定義目前 AI Tutor 的「可呼叫契約面」。

目前正式可用路徑為：

- Bridge Stdio command：`tutor_reply`

尚未完成路徑（規劃中）：

- HTTP `POST /api/tutor/reply`

## 2. 傳輸 Envelope

### 2.1 Request Envelope

透過 bridge 送入的 request 需為 JSON object，Tutor 使用以下格式：

```json
{
  "command": "tutor_reply",
  "payload": {
    "question": "How should I start?",
    "provider": "template",
    "level_id": "group-01-demo",
    "python_code": "print(1)\n",
    "block_json": {"kind": "workspace"}
  }
}
```

### 2.2 Response Envelope

Tutor 回傳仍沿用 bridge 統一外層：

```json
{
  "ok": true,
  "state": {},
  "tutor": {
    "reply_type": "next_step_hint",
    "content": "先確認輸入輸出格式。",
    "metadata": {}
  },
  "error": null,
  "debug": {}
}
```

規則：

- `ok = true`：`state` 一定存在，`error = null`
- `ok = false`：`state = null`、`tutor = null`，`error` 為可讀訊息

## 3. TutorReplyRequest 契約

對應型別：`integration.contracts.TutorReplyRequest`

### 3.1 欄位定義

- `question: str`（必填，非空）
- `provider: str`（選填，預設 `template`）
- `level_id: str | null`（選填）
- `python_code: str`（選填，預設空字串）
- `block_json: object | null`（選填，需為 object 或 null）
- `conversation_id: str | null`（選填）
- `conversation_history: array<object>`（選填）
- `history_summary: str | null`（選填）
- `recent_feedback: array<string>`（選填，會提供最近一次 analysis/judge 重點摘要）
- `provider_options: object`（選填，預設 `{}`）

### 3.2 相容 alias

為了與先前 payload 相容，deserialize 會接受：

- `current_code` -> `python_code`
- `current_blocks` -> `block_json`
- `submission_history` -> `recent_feedback`

此外，下列欄位若直接出現在 payload，會併入 `provider_options`（若尚未存在同名鍵）：

- `endpoint_url`
- `model`
- `api_key`
- `system_prompt`
- `timeout_sec`

### 3.3 Provider 值

目前支援：

- `template`
- `stub`
- `local`
- `openai_compatible`

`openai_compatible` 需要 `provider_options` 內至少提供：

- `endpoint_url`（非空字串）
- `model`（非空字串）
- `api_key`（非空字串）

可選：

- `timeout_sec`（正數）
- `system_prompt`（字串）

## 4. TutorReplyPayload 契約

對應型別：`integration.contracts.TutorReplyPayload`

- `reply_type: str`
- `content: str`
- `metadata: object`

### 4.1 reply_type 目前可能值

- `concept_explanation`
- `next_step_hint`
- `debug_hint`
- `scope_refusal`
- `solution_refusal`

### 4.2 metadata 常見欄位

實際值依 provider/服務流程決定，常見包含：

- `provider`
- `attempt`
- `history_compressed`
- `history_token_estimate`
- `missing_skill_ids`
- `error_code`
- `fallback`
- `model`
- `usage`

## 5. 錯誤行為

### 5.1 契約驗證錯誤（request 不合法）

- 來源：`deserialize_tutor_reply_request`
- bridge 回傳：`ok=false`，`error` 含 validation 訊息

### 5.2 業務驗證錯誤（如 level 不存在）

- 來源：`BridgeServer._handle_tutor_reply`
- bridge 回傳：`ok=false`，`error` 為文字訊息

### 5.3 Provider 失敗但服務可 fallback

- 來源：`TutorService.reply`
- bridge 回傳：`ok=true`
- `tutor.reply_type=scope_refusal`
- `tutor.metadata.error_code=provider_unavailable`

## 6. 使用範例

### 6.1 最小 template 請求

```json
{
  "command": "tutor_reply",
  "payload": {
    "question": "How should I start?",
    "provider": "template"
  }
}
```

### 6.2 OpenAI compatible 請求

```json
{
  "command": "tutor_reply",
  "payload": {
    "question": "Explain this step",
    "provider": "openai_compatible",
    "level_id": "group-01-practice-01",
    "python_code": "print(1)\n",
    "provider_options": {
      "endpoint_url": "https://example.invalid/v1/chat/completions",
      "model": "gpt-x",
      "api_key": "***",
      "timeout_sec": 20
    }
  }
}
```

## 7. 與 Phase 3 的銜接

Phase 3 若新增 HTTP route，建議沿用本文件中的 request/response shape，避免 Godot 與 bridge 雙軌契約分歧。

建議策略：

1. Router 層直接使用 `TutorReplyRequest` / `TutorReplyPayload` 等價結構
2. 保留 alias 解析只在 bridge 或 adapter 層，避免核心服務增加分支
3. 文件更新順序：先更新本文件，再更新 router 與 client

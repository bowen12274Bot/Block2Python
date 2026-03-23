# Practice Feedback State Mapping

- 版本：v0.1
- 日期：2026-03-23
- 狀態：Draft
- 適用範圍：Godot `practice` 頁 feedback 狀態映射

## 1. 目的

本規格定義 `practice` 頁 feedback 的狀態映射方式，將底層執行/判題事實轉成 Godot client 可直接渲染的 feedback view。

本規格的目標是：

- 固定 feedback 可用的 UI state 集合
- 固定 presenter 最小輸出欄位
- 固定成功/錯誤/拒絕的文案與 fallback 規則
- 對齊 feedback panel 的前端布局責任
- 避免 `game_flow_feedback_presenter.gd` 再將所有資訊壓成單一 `body` 字串

本規格不處理：

- `demo` 頁 guidance
- `scene` 頁 guidance
- feedback panel 的最終視覺樣式
- Python dataclass schema 的正式改版

## 2. 術語

### 2.1 事實層

事實層是 presenter 讀取的輸入事實，來源可由：

- `state.last_submission`
- 目前畫面 mode
- 目前操作來源

共同推得。

事實層不直接等於 UI state。

### 2.2 UI 狀態層

UI 狀態層是 feedback panel 真正渲染時使用的固定狀態集合。

畫面不得直接吃 judge 原始值；必須先由 presenter 將事實層映射成 UI 狀態層。

## 3. 輸入事實欄位

presenter 的最小輸入事實欄位如下：

- `action_type`
  - `idle | run | submit`
- `source_type`
  - `python | toolbox | system`
- `has_runtime_error`
  - `true | false`
- `stdout_text`
  - string
- `error_text`
  - string
- `judge_status`
  - `accepted | rejected | none`
- `review_mode`
  - `true | false`

補充說明：

- `action_type=run` 同時涵蓋 Python Run 與 Tool Kit Run
- `source_type=toolbox` 不新增獨立 UI state，只影響文案
- `judge_status` 只對正式 submit 有意義；run 預設應視為 `none`

## 4. UI Feedback State 集合

本規格只定義以下 6 種 feedback state：

- `idle`
- `run_success`
- `run_error`
- `submit_success`
- `submit_error`
- `submit_rejected`

約束：

- `run_toolbox` 不新增獨立 state
- `review_mode` 不改變主 state
- 後續若要擴充新的 state，必須先更新本規格

## 5. 最小輸出 View Contract

presenter 最終輸出至少必須包含：

- `feedback_state`
- `status_text`
- `is_success`
- `content_text`

欄位用途：

- `feedback_state`
  - UI 使用的固定狀態值
- `status_text`
  - 右上角狀態 badge 文字
- `is_success`
  - 供 UI 決定成功/錯誤樣式
- `content_text`
  - feedback 主內容區全文

## 5.1 前端布局規格

feedback panel 應採用以下布局：

- 左上：固定標題 `Diagnostic Output`
- 右上：狀態 badge，顯示 `status_text`
- 主內容區：整塊文字區，直接顯示 `content_text`

本規格不再要求顯示第二層標題，例如：

- `輸出：`
- `錯誤：`
- `系統：`

成功、錯誤與待命狀態，均共用同一塊主內容區。

## 6. 狀態映射規則

### 6.1 核心映射

| action_type | has_runtime_error | judge_status | feedback_state |
| --- | --- | --- | --- |
| `idle` | - | - | `idle` |
| `run` | `true` | `none` | `run_error` |
| `run` | `false` | `none` | `run_success` |
| `submit` | `true` | `none` | `submit_error` |
| `submit` | `false` | `accepted` | `submit_success` |
| `submit` | `false` | `rejected` | `submit_rejected` |
| `submit` | `false` | `none` | `submit_error` |

### 6.2 映射補充規則

- `submit` 在無 runtime error、但沒有明確 judge 結果時，必須映射為 `submit_error`
- `run` 一律不看 `judge_status=accepted/rejected`
- `source_type` 不決定 `feedback_state`
- `review_mode` 不決定 `feedback_state`

## 7. 文案規則

### 7.1 status_text

| feedback_state | source_type | status_text |
| --- | --- | --- |
| `idle` | `system` | `待命中` |
| `run_success` | `python` | `執行成功` |
| `run_success` | `toolbox` | `工具包執行成功` |
| `run_error` | `python` | `執行錯誤` |
| `run_error` | `toolbox` | `工具包執行錯誤` |
| `submit_success` | `python` | `提交成功` |
| `submit_error` | `python` | `提交錯誤` |
| `submit_rejected` | `python` | `提交失敗` |

### 7.2 is_success

- `true`
  - `run_success`
  - `submit_success`
- `false`
  - `idle`
  - `run_error`
  - `submit_error`
  - `submit_rejected`

### 7.3 content_label

本版規格已移除 `content_label`，由 `status_text` 與 `content_text` 直接承擔狀態與內容呈現。

## 8. content_text fallback 規則

### 8.1 成功類 state

成功類 state 的 `content_text` 來源優先順序：

1. `stdout_text`
2. `submit_success` 時，使用 `答案正確，已完成本題。`
3. 其他成功狀態時，使用 `執行完成。`

### 8.2 錯誤類 state

錯誤類 state 的 `content_text` 來源優先順序：

1. `error_text`
2. `submit_rejected` 時，使用 `輸出與預期結果不一致。`
3. 其他錯誤狀態時，使用 `發生未知錯誤。`

### 8.3 idle

`idle` 的 `content_text` 固定為：

`先執行程式或提交答案。`

### 8.4 review mode 附加提示

當 `review_mode=true` 時：

- 不改變 `feedback_state`
- 不改變 `status_text`
- 僅在 `content_text` 末尾追加：

`目前為複習模式，不影響已完成進度。`

## 9. 驗收範例

### 9.1 初始待命

輸入事實：

- `action_type=idle`
- `source_type=system`

輸出：

- `feedback_state=idle`
- `status_text=待命中`
- `content_text=先執行程式或提交答案。`

### 9.2 Python Run 成功

輸入事實：

- `action_type=run`
- `source_type=python`
- `has_runtime_error=false`
- `stdout_text=Hello, Alice`
- `judge_status=none`

輸出：

- `feedback_state=run_success`
- `status_text=執行成功`
- `content_text=Hello, Alice`

### 9.3 Python Run 錯誤

輸入事實：

- `action_type=run`
- `source_type=python`
- `has_runtime_error=true`
- `error_text=NameError: name 'nam' is not defined`
- `judge_status=none`

輸出：

- `feedback_state=run_error`
- `status_text=執行錯誤`
- `content_text=NameError: name 'nam' is not defined`

### 9.4 Tool Kit Run 成功

輸入事實：

- `action_type=run`
- `source_type=toolbox`
- `has_runtime_error=false`
- `stdout_text=Hello, Alice`
- `judge_status=none`

輸出：

- `feedback_state=run_success`
- `status_text=工具包執行成功`
- `content_text=Hello, Alice`

### 9.5 Tool Kit Run 錯誤

輸入事實：

- `action_type=run`
- `source_type=toolbox`
- `has_runtime_error=true`
- `error_text=缺少輸入節點`
- `judge_status=none`

輸出：

- `feedback_state=run_error`
- `status_text=工具包執行錯誤`
- `content_text=缺少輸入節點`

### 9.6 Python Submit 成功

輸入事實：

- `action_type=submit`
- `source_type=python`
- `has_runtime_error=false`
- `judge_status=accepted`
- `stdout_text=""`

輸出：

- `feedback_state=submit_success`
- `status_text=提交成功`
- `content_text=答案正確，已完成本題。`

### 9.7 Python Submit 錯誤

輸入事實：

- `action_type=submit`
- `source_type=python`
- `has_runtime_error=true`
- `error_text=IndentationError: expected an indented block`
- `judge_status=none`

輸出：

- `feedback_state=submit_error`
- `status_text=提交錯誤`
- `content_text=IndentationError: expected an indented block`

### 9.8 Python Submit Rejected

輸入事實：

- `action_type=submit`
- `source_type=python`
- `has_runtime_error=false`
- `judge_status=rejected`
- `error_text=""`

輸出：

- `feedback_state=submit_rejected`
- `status_text=提交失敗`
- `content_text=輸出與預期結果不一致。`

## 10. Rendered Output 範例

### 10.1 Idle

```text
Diagnostic Output                               [待命中]

先執行程式或提交答案。
```

### 10.2 Python Run 成功

```text
Diagnostic Output                               [成功輸出]

Hello, Alice
```

### 10.3 Python Run 錯誤

```text
Diagnostic Output                               [執行錯誤]

NameError: name 'nam' is not defined
```

### 10.4 Tool Kit Run 成功

```text
Diagnostic Output                           [工具包成功輸出]

Hello, Alice
```

### 10.5 Submit 成功

```text
Diagnostic Output                               [提交成功]

答案正確，已完成本題。
```

### 10.6 Submit Rejected

```text
Diagnostic Output                               [提交錯誤]

輸出與預期結果不一致。
```

## 11. Implementation Acceptance

後續實作若對齊本規格，至少應滿足：

- `game_flow_feedback_presenter.gd` 不再把所有訊息直接壓成單一 `body`
- `feedback_panel.gd` 應以 `status_text + content_text` 為主渲染
- `feedback_panel.gd` 應將 `status_text` 放在框的右上角，`content_text` 佔用主內容區
- `toolbox` 僅改變 `source_type`，不新增獨立 UI state
- Python contract / projection 若後續擴充欄位，應維持可映射到本規格定義的輸入事實欄位

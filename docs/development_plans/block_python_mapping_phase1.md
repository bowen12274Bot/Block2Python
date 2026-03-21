# 首波積木 Python 對應與技術驗證規劃

## 1. 文件定位

本文件承接 `block_scope_phase1.md`，目的是定義首波積木的 Python 對應方式與技術驗證方向。

本文件服務於技術驗證與 prototype 前置準備，不是完整 Blockly API 規格，也不是最終產品文件。

本文件只涵蓋第一批積木，不討論第二批或第三批內容。

## 2. 現況前提

目前系統的提交主鏈路為 `python_code -> analysis -> judge`。

`Submission.block_json` 已存在，但目前不是正式驗證主體，因此首波 mapping 的前提是：積木能穩定輸出 Python，並沿用既有驗證流程。

目前 `AstAnalyzer` 已有全域禁用規則，像 `while`、`list`、`dict`、`tuple`、`import`、`def`、`class` 目前不適合作為首波範圍。

因此首波規劃的重點，不是追求 Blockly 全量能力，而是先確保第一批積木有穩定、可驗證、可教學的 Python 對應方式。

## 3. 首波積木對應表

| 積木類別 | 教學目的 | 固定 Python 輸出樣式 | 備註 / 限制 |
| --- | --- | --- | --- |
| `print` | 顯示輸出結果 | `print(<expr>)` | 首波只處理單次輸出與單一表達式輸出 |
| `input` | 取得玩家輸入 | `input()` | 首波不處理複合輸入模式 |
| `int` | 將文字輸入轉為整數 | `int(<expr>)` | 首波常見組合為 `int(input())` |
| 變數指定 | 建立並儲存資料 | `<name> = <expr>` | 首波只處理單一變數指定 |
| 變數取值 | 讀取既有變數 | `<name>` | 首波不處理複雜作用域 |
| 數學運算 | 進行基本加減乘除 | `<left> + <right>`、`-`、`*`、`/` | 首波先聚焦二元運算 |
| 比較運算 | 進行條件比較 | `== != > < >= <=` | 首波不處理複合布林鏈結 |
| `if` | 單一條件判斷 | `if <condition>:` | 下方區塊為 `<statements>` |
| `if / else` | 條件分支處理 | `if <condition>:` / `else:` | 首波固定保留完整 `else` 分支 |
| `for in range(n)` | 固定次數迴圈 | `for i in range(<expr>):` | 首波固定迴圈變數名稱為 `i`，不開放進階 range 形式 |

### `if` 固定寫法

```python
if <condition>:
    <statements>
```

### `if / else` 固定寫法

```python
if <condition>:
    <statements>
else:
    <statements>
```

### `for in range(n)` 固定寫法

```python
for i in range(<expr>):
    <statements>
```

首波直接固定迴圈變數名稱為 `i`，且不開放 `range(start, end)` 與 `range(start, end, step)`。

## 4. 首波限制與不處理事項

首波不處理以下內容：

- `while`
- `function / def`
- `class`
- `import`
- `list`
- `dict`
- `tuple`
- 自訂 block
- 以 `block_json` 做結構驗證

首波也不處理多種 Python 生成樣式，而是先固定一種最小樣式，以降低技術驗證與教學對齊成本。

## 5. 教學主題對應

首波積木對應以下教學主題：

- `Input Gate`
- `Variable Base`
- `If Canyon`
- `Loop Lab`
- `牛刀小試`

`Input Gate` 主要依賴 `input`、`int`、`print`，建立玩家輸入與輸出結果的基本互動。

`Variable Base` 主要依賴變數指定、變數取值與基本運算，讓玩家開始理解資料儲存與運算流程。

`If Canyon` 主要依賴比較運算、`if`、`if / else`，建立條件判斷與分支概念。

`Loop Lab` 主要依賴 `for in range(n)`，讓玩家練習固定次數的重複動作。

`牛刀小試` 則作為上述積木的綜合應用，不額外增加新的首波積木類型。

## 6. 技術驗證清單

本節不是實作步驟，而是 prototype 前需要確認的檢查點。

### 輸入輸出

- `input()` 是否能穩定接到 judge 測資的 stdin。
- `int(input())` 是否符合目前預期的輸入題型。
- `print(...)` 是否能被既有 output normalization 正常比對。

### 變數與運算

- 變數指定與取值是否不需額外 analyzer 支援。
- 加減乘除是否足夠支撐前 2 關題型需求。

### 條件判斷

- `if` / `if else` 是否能由現有 `required_keywords` 規則做第一層驗證。
- 比較運算是否足以支撐條件題型。

### 迴圈

- `for i in range(n)` 是否足夠支撐 `Loop Lab` 的題型需求。
- 是否暫不支援巢狀迴圈與進階 `range` 形式。

### 提交流程

- Blockly 產出的 `python_code` 是否能直接送入現有 `Submission`。
- `block_json` 是否先只保留存檔與除錯用途，不進入驗證邏輯。

## 7. 後續銜接

待首波 prototype 驗證完成後，再評估是否補第二批積木 mapping 文件，或擴充 `block_json` 驗證策略。

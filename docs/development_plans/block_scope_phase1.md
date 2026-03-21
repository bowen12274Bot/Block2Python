# 首波積木導入範圍規劃

## 1. 文件定位

本文件用於定義首波 Blockly 積木引入範圍，作為教案尚未完全穩定前的範圍控制依據。
目前教案方向仍可能調整，因此本文件先只收斂第一批積木，不討論完整 Blockly API，也不延伸到後續批次的積木擴充內容。

## 2. 首波導入原則

- 只引入能支撐前段教學主線的最小積木集合。
- 優先選擇 Python 對應單純、驗證方式清楚、教學價值高的積木。
- 目前先依賴既有 `python_code -> analysis -> judge` 鏈路，不在本階段規劃完整 `block_json` 驗證。
- 本階段不追求完整 Blockly 支援，也不以覆蓋全部 Python 語法為目標。

## 3. 首波積木清單

| 積木類別 | 積木用途 | 對應 Python | 對應教學主題 |
| --- | --- | --- | --- |
| `print` | 顯示輸出結果 | `print(...)` | `Input Gate` |
| `input` | 取得玩家輸入 | `input()` | `Input Gate` |
| `int` | 將輸入文字轉成整數 | `int(...)` | `Input Gate`、`Variable Base` |
| 變數指定 | 建立變數並存放資料 | `x = ...` | `Variable Base` |
| 變數取值 | 讀取既有變數內容 | `x` | `Variable Base`、`If Canyon`、`Loop Lab` |
| 數學運算 | 進行加減乘除計算 | `+` `-` `*` `/` | `Variable Base`、`牛刀小試` |
| 比較運算 | 判斷大小與相等關係 | `==` `!=` `>` `<` `>=` `<=` | `If Canyon` |
| `if` | 單一條件判斷 | `if ...:` | `If Canyon` |
| `if / else` | 條件分支處理 | `if ...: ... else: ...` | `If Canyon`、`牛刀小試` |
| `for in range(n)` | 固定次數迴圈 | `for i in range(n):` | `Loop Lab`、`牛刀小試` |

## 4. 教學主題對應

首波積木主要支撐以下教學主題：

- `Input Gate`
- `Variable Base`
- `If Canyon`
- `Loop Lab`
- `牛刀小試`

這代表首波積木的目標，是先支撐前 5 關的核心教學主線，讓輸入、變數、條件判斷、迴圈與基礎綜合應用可以先成立。

## 5. 驗證可行性說明

目前系統已具備 Python 提交、analysis、judge 的基本鏈路，因此首波評估前提是：只要積木能穩定轉成 Python，就可以沿用現有驗證流程。

以目前 repo 狀態來看，首波積木的 Python 對應相對單純，驗證風險也較低，適合作為第一階段導入範圍。

本階段先不處理以下內容：

- 完整 Blockly API 對接
- `block_json` 結構驗證
- 進階資料結構積木
- `tuple`、`class`、`function`、`while` 等進階語法

## 6. 後續銜接

待教案穩定後，再另行評估後續積木擴充與 Python 對應文件。

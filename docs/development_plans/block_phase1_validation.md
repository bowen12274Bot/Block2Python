# 第一批積木實測驗證

## 1. 文件定位

本文件記錄第一批積木的實測驗證結果，目的是確認：

- 第一批積木是否能穩定產生可用的 Python
- 產生的 Python 是否能接上既有 `analysis -> judge` 驗證鏈路
- 外部工具包驗證流程是否能和 Godot challenge 頁正常協作

本文件只涵蓋第一批積木，不展開第二批積木或後續教案擴充。

## 2. 驗證前提

本輪驗證以前述 phase 1 規劃為前提：

- 積木範圍以 [block_scope_phase1.md](./block_scope_phase1.md) 為準
- Python 對應方式以 [block_python_mapping_phase1.md](./block_python_mapping_phase1.md) 為準
- 工具包採外部 PySide6 浮動視窗
- challenge 頁仍是正式遊玩主畫面
- toolbox `Verify` 只做 verification-only，不做正式清關

## 3. 驗證範圍

本輪實測聚焦以下項目：

- `input / int / print`
- `if`
- `for in range(n)`
- 空 workspace / 鎖定積木 / 錯誤情況的防呆

對應題目如下：

| 驗證項目 | 對應題目 | 驗證目的 |
| --- | --- | --- |
| `input / int / print` | `group-01-practice-01` | 驗證輸入輸出與基本生成流程 |
| `if` | `group-01-practice-04` | 驗證條件判斷積木與 judge/analysis 相容性 |
| `for in range(n)` | `group-01-practice-05` | 驗證迴圈積木與 judge/analysis 相容性 |
| 失敗防呆 | 同一套工具包流程 | 驗證空積木、鎖定積木與錯誤輸入時的保護行為 |

## 4. 驗證結果

### 4.1 單題驗證結果

- `group-01-practice-01`：通過
- `group-01-practice-04`：通過
- `group-01-practice-05`：通過

### 4.2 流程驗證結果

以下流程已實際驗證可用：

- Godot challenge 頁可開啟外部 PySide6 工具包
- 工具包可產生 Blockly 對應的 `python_code` 與 `block_json`
- `Verify` 後 challenge 頁可收到並顯示同一份驗證結果
- verification-only 不會誤判為正式通關
- Godot 的 Python 編輯區內容在 `Verify` 後保持原樣，不會被 Blockly 生成碼覆蓋
- 關閉工具包後，challenge 頁可恢復 Python 編輯與正式提交

### 4.3 防呆驗證結果

以下保護行為已驗證成立：

- 空 workspace 不會送出有效 verify request
- 未開放的積木會被 allowlist 擋下
- 錯誤組法或不合法 workspace 會停在工具包端，不直接進入正式驗證
- `Verify` 成功不會自動 cleared level

## 5. 結論

本輪結果可下以下結論：

- 第一批積木的首波技術驗證可行
- `input / int / print`、`if`、`for in range(n)` 已達到 prototype 級可用
- 目前的 `python_code -> analysis -> judge` 主鏈路可直接重用，不需要另做一套積木專用判題核心
- 外部 PySide6 工具包方案可取代原本的 Godot WRY 內嵌方案，並避開原生 WebView 焦點殘留問題

## 6. 目前仍保留的限制

雖然第一批積木已通過首波驗證，但目前仍有以下限制：

- 驗證完成不代表第二批積木可直接比照導入
- `block_json` 目前仍以 workspace 保存與後續擴充為主，不是正式驗證主體
- `if / else` 雖已有對應規劃，但仍可依教案進度選擇是否開放
- 關卡對應的積木 allowlist 目前仍需持續收斂成更明確的 policy 管理方式

## 7. 建議下一步

本輪驗證完成後，建議下一步優先順序如下：

1. 將第一批積木的可用範圍視為已驗證 baseline
2. 規劃關卡 / toolbox policy 如何控制每題可用積木
3. 在不擴大範圍的前提下，持續把第一批積木的教學規則收斂為正式產品規格
4. 待教案穩定後，再評估第二批積木的導入與驗證
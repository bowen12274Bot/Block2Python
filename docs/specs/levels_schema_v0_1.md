# 關卡檔 Schema 規範（v0.1 / 寬鬆版）

- 文件版本：0.1
- 建立日期：2026-03-04
- 適用範圍：Demo / 初期建立階段
- 規範策略：**先與程式行為一致（寬鬆載入）**，等初期階段完成後再改成嚴格驗證（例如多餘欄位/型別錯誤即報錯）。
- 來源對齊（source of truth）：`src/block2python/app/levels_loader.py`

## 1. 目錄結構

預設資料夾：`assets/levels/`

必要檔案：

- `assets/levels/index.json`：關卡索引（列出所有關卡檔）
- `assets/levels/<level>.json`：單一關卡內容

可選：

- 也可透過環境變數 `BLOCK2PYTHON_LEVELS_DIR` 指定關卡目錄（由程式讀取）

## 2. index.json 規格

檔案：`assets/levels/index.json`

### 2.1 JSON 結構

必要欄位：

- `levels`：array
  - 每個元素為 object，必要欄位：
    - `id`：string（對應關卡 id）
    - `file`：string（相對於 `assets/levels/` 的檔名）

可選欄位：

- `schema_version`：string（目前僅作為文件/資料版本註記，程式不依此做邏輯分支）

### 2.2 範例

參考：`assets/levels/index.json`

```json
{
  "schema_version": "0.1",
  "levels": [
    { "id": "demo-1", "file": "demo-1.json" },
    { "id": "demo-2", "file": "demo-2.json" }
  ]
}
```

## 3. 單關卡 level.json 規格

檔案：`assets/levels/<level>.json`

### 3.1 必要欄位（缺少會載入失敗）

- `level_id`：string
- `title`：string

### 3.2 可選欄位（缺少會使用預設值）

基本資訊：

- `prompt`：string（預設 `""`）
- `chapter_id`：string|null（預設 `null`）
- `quest_id`：string|null（預設 `null`）
- `order_index`：int|string|null（可轉 int；預設 `null`）

教學/劇情內容（先直接內嵌文字）：

- `learning_markdown`：string（預設 `""`）
- `story_intro_markdown`：string（預設 `""`）
- `story_outro_markdown`：string（預設 `""`）

解鎖流程：

- `prerequisite_level_ids`：array[string|int]（預設 `[]`；載入後轉為 tuple[str,...]）
- `next_level_ids`：array[string|int]（預設 `[]`；載入後轉為 tuple[str,...]）

測資：

- `testcases`：array（預設 `[]`）
  - 每個 testcase 為 object，可選欄位：
    - `name`：string（預設 `null`）
    - `stdin`：string（預設 `""`）
    - `expected_stdout`：string（預設 `""`）

Blockly schema（預留）：

- `block_schema_version`：string|null（預設 `null`）
  - 若尚未定版，也允許先寫在 `metadata`（例如 `metadata["block_schema_version"]`）避免過早綁死。

擴充欄位：

- `metadata`：object（預設 `{}`）
  - 允許放任何自訂 key，程式會原樣帶入 `LevelSpec.metadata`

### 3.3 目前「寬鬆載入」的注意事項

- 只有上述欄位會被載入；不在清單中的欄位目前會被忽略（不會自動併入 `metadata`）。
- `testcases` 內的 `stdin/expected_stdout` 若缺少，會被當成空字串。

### 3.4 dev-only（Demo 期繞過驗證用）

以下欄位屬於 Demo 期 stub 設定，**不是最終產品規格的一部分**，目前建議放在 `metadata`：

- `metadata.stub_judge`：供 `StubJudge` 使用
  - `status`：`"AC"|"WA"|"TLE"|"RE"`
  - `summary`：string
- `metadata.stub_analysis`：供 `StubAnalyzer` 使用
  - `status`：`"PASS"|"FAIL"|"SYNTAX_ERROR"`
  - `summary`：string
  - `violations`：array（可選；每項建議至少含 `rule_id`、`message`、`severity`）

### 3.5 範例

參考：`assets/levels/demo-1.json`、`assets/levels/demo-2.json`


# Block JSON Schema（v0.1 / 建立期）

- 文件版本：0.1
- 建立日期：2026-03-04
- 適用範圍：Demo / 初期建立階段
- 目標：定義「視覺化編程層 → Python/分析層」之間可交換的最小 Block JSON 格式，讓 Web↔Desktop 資料流可版本化與可擴充。

> 本規格先以「能保存/還原 Blockly workspace 狀態」為主；暫不強制要求與 AST 之間的一一映射（後期再擴充）。

## 1. 檔案形式與傳輸

- 表示形式：JSON object
- 在本專案的使用方式：
  - Web（Blockly）端輸出 JSON
  - Desktop 端以 `Submission.block_json` 接收
- 版本欄位：
  - 由 `schema_version` 標示此 JSON 的 schema 版本

## 2. Top-level 結構

必要欄位：

- `schema_version`：string
  - 固定為 `"0.1"`
- `workspace`：object|null
  - 為 Blockly workspace 的序列化結果
  - 建立期建議使用 Blockly 官方 serialization API：
    - `Blockly.serialization.workspaces.save(workspace)`
  - 若序列化 API 不可用，可暫設為 `null`，並在 `metadata` 留下 fallback（見下方）

可選欄位：

- `generated`：object
  - `python`：string（生成的 Python code；可與 Desktop 端填入 editor 的內容一致）
- `metadata`：object
  - 自由擴充欄位（建立期可用）
  - 建議至少包含：
    - `blockly_version`：string（若可取得）
    - `locale`：string（例如 `zh-hant`）
    - `created_at`：string（ISO 8601，選配）

## 3. 範例

### 3.1 最小範例（推薦）

```json
{
  "schema_version": "0.1",
  "workspace": {
    "blocks": {
      "languageVersion": 0,
      "blocks": []
    }
  }
}
```

### 3.2 含 generated 與 metadata

```json
{
  "schema_version": "0.1",
  "workspace": {
    "blocks": {
      "languageVersion": 0,
      "blocks": []
    }
  },
  "generated": {
    "python": "print('Hello')\n"
  },
  "metadata": {
    "locale": "zh-hant",
    "blockly_version": "12.4.1"
  }
}
```

## 4. 相容性與演進策略（建立期）

- Desktop 端讀取原則（建議）：
  - 若 `schema_version != "0.1"`：先視為不相容，仍可保留原始資料於 debug/metadata，避免直接丟棄
  - 若 `workspace` 缺失或非 object：視為輸出不完整，回報可理解的錯誤（不致崩潰）
- 後續演進方向（v0.2+）：
  - 引入「關卡允許/禁止積木」對應欄位
  - 引入更明確的「概念/結構標籤」以支援 AST 映射與教學提示
  - 版本化策略：新增欄位優先，避免破壞既有欄位語意


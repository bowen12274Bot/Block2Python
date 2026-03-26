# 規格（Specs）

本資料夾用於存放「詳細實作細節」與「API 規範」等較偏規格書性質的文件，避免與 `docs/technical_rationale.md`（技術策略/合理性）混在一起。

- 關卡檔 schema（v0.1）：`docs/specs/levels_schema_v0_1.md`
- Block JSON schema（v0.1）：`docs/specs/block_json_schema_v0_1.md`
- 遊戲第一個切片 schema（v0.1）：`docs/specs/game_slice_schema_v0_1.md`
- practice feedback 狀態映射規格：`docs/specs/practice_feedback_state_mapping_v0_1.md`
- 遊戲第一個切片內容樣板：`docs/specs/examples/`

目前樣板包含：

- nodes / quest / scene / challenge
- toolbox / battery
- savegame example

建議內容範例（依實際需要增修）：

- API 規格（請求/回應格式、錯誤碼、範例）
- Block JSON schema 與版本策略
- AST 分析輸出格式（差異摘要結構）
- 判題/驗證介面規格（AC/WA、差異、超時、RE/TLE）
- AI 上下文組裝與邊界規格（可讀內容、拒答規則、教案橋接格式）

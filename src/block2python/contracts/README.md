# Contracts（資料契約）

本資料夾預留放「跨層資料契約」與介面定義（Judge/Analysis/AI/Blockly Adapter 的輸入輸出型別）。

目標：

- 先定義資料結構，再逐步替換各層 stub → 真實實作
- 讓 UI/CLI 能先串起端到端流程

目前已先以 `dataclass` 建立最小契約：`src/block2python/contracts/models.py`（LevelSpec/Submission/JudgeResult/AnalysisResult 等）。

補充約定（目前狀態）：

- `LevelSpec` 先把「教學/劇情/解鎖」相關欄位一併納入（例如 `chapter_id`、`quest_id`、`learning_markdown`、`prerequisite_level_ids`、`next_level_ids`）。
- `schema_version`（Blockly/Block JSON）先保留在 `LevelSpec.block_schema_version` / `Submission.block_schema_version`；若尚未定版，暫時可先放在 `metadata`（例如 `metadata["block_schema_version"]`）以避免過早綁死格式。

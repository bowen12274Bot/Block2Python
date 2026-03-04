# Source（src/）

主要程式碼放在 `src/block2python/`。

建議對應 `docs/uml/system_architecture.md` 的分層：

- `block2python/app/`：應用整合層（PySide6 App Shell / 狀態與流程）
- `block2python/judge/`：程式執行與判題
- `block2python/analysis/`：AST 分析與結構檢查
- `block2python/blockly/`：Blockly 嵌入與資料橋接
- `block2python/ai/`：AI 提示與邊界控制
- `block2python/contracts/`：跨層資料契約（型別/資料結構）


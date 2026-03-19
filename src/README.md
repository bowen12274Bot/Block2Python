# Source 結構

這個目錄放的是 Python 套件程式碼，主要內容在 `src/block2python/`。

## 目前的頂層套件

- `block2python/content/`
  負責遊戲內容的載入、組裝、資料模型，以及內容 runtime helper。
- `block2python/level_play/`
  負責 level 實際遊玩時的流程、judge 建立、progress 儲存，以及 `AppCore`。
- `block2python/game/`
  負責 `GameSession` 與 savegame 相關邏輯。
- `block2python/integration/`
  對外整合邊界，主要給 Godot bridge 這類外部 client 使用。
- `block2python/judge/`
  判題實作，包含 stub judge 與 Wasm judge。
- `block2python/clients/`
  非主線的 Python client 與 bootstrap helper。
  目前產品主 client 是 Godot，這裡的 CLI 與 PySide6 屬於次要工具。
- `block2python/contracts/`
  核心 contracts，包含 level、submission、analysis、judge result 等資料結構。
- `block2python/analysis/`
  靜態分析相關的介面與實作。

## 預留命名空間

- `block2python/ai/`
  預留給未來 AI 相關模組。
- `block2python/blockly/`
  預留給未來 Blockly 相關的 Python 模組。

## 備註

- 舊的 shim 套件 `block2python.app`、`block2python.game_content`、`block2python.ui` 已移除。
- 根入口 `block2python/__main__.py` 現在只負責列出可用 entrypoints，不再默默預設跑舊 CLI。
- 更高層的架構說明可參考 `docs/project_architecture.md` 與 `docs/uml/system_architecture.md`。


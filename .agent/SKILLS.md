# Skills Index

以下列出目前放在 `.agent/skills/` 的 repo 內技能。這些技能是本專案的 canonical skills。

## 原則

- `.agent/skills/` 是 repo 內 skill 的 source of truth。
- 每個 skill 的入口都是該目錄下的 `SKILL.md`。
- 若問題明顯屬於 repo-specific 工作方式，優先使用這裡的 skill。

## Available Skills

- `contributing`
  用於快速上手、開發環境設定、Git workflow、Blockly vendor、驗證流程與協作規範導讀。
- `development-planning`
  - 用於整理功能計畫、拆解工作項目與規劃 AI 協作開發順序。
- `feature-implementation`
  - 用於 Block2Python 的功能實作、修 bug、重構與一般程式碼修改。
- `project-architecture`
  - 用於整理 repo 架構、模組職責與跨模組設計方向。
- `game-product-direction`
  - 用於整理遊戲產品方向、遊戲化設計與整體體驗目標。
- `game-story-background`
  - 用於整理世界觀、劇情背景與角色設定。
- `block2python-common-troubleshooting`
  - 用於排查 Block2Python repo 常見開發問題，例如測試、temp、cache、git 權限與 PowerShell 指令相容性。
- `skill-creator`
  - 用於建立或更新 repo 內的 canonical skills。
- `encoding-safe-writes`
  - 用於修正亂碼、避免 PowerShell 寫檔改壞編碼，並驗證 UTF-8 位元組是否正確。

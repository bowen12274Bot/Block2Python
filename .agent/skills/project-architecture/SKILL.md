---
name: project-architecture
description: 理解 Block2Python 專案架構、模組分層、資料夾責任與功能落點。用於建立全局架構理解、回答架構問題、判斷新功能應放哪裡、比較文件與實際 repo 結構差異，或分析 agent skills 與專案分層關係時。
---

# Project Architecture

使用此 skill 來建立 Block2Python 的整體架構理解，而不只是轉述架構文件。

## 目標

- 建立對專案目前架構的全局理解
- 理解 `docs/`、`src/`、`assets/`、`tools/`、`tests/`、`.agent/` 的責任分工
- 判斷新功能、資料、腳本或文件應落在哪個位置
- 比較架構文件與實際 repo 現況是否一致
- 協助其他 skills 或實作任務使用一致的架構判準

## 建立架構理解

回答前，依序建立以下三層理解：

1. 文件層
   先讀 `docs/project_architecture.md`，必要時補讀 `docs/technical_rationale.md`、`docs/uml/`。

2. 結構層
   檢查實際 repo 結構，至少包含根目錄、`src/`、`assets/`、`tools/`、`.agent/skills/`。

3. 差異層
   比對文件描述與 repo 現況。若兩者不一致，優先指出差異，再說明目前較可信的判斷依據。

## 分析重點

分析時優先回答這些問題：

- 這個東西屬於哪一層？
- 這個責任應由哪個目錄或模組承擔？
- 它為什麼應該放這裡，而不是別處？
- 目前文件和程式碼是否一致？
- 若要新增功能，會影響哪些層？

## 回答策略

- 先回答現況，再回答設計意圖。
- 先說明分層與責任，再給具體路徑。
- 對於「應該放哪裡」這類問題，必須附上排除理由，說明為什麼不放其他位置。
- 對於不確定或文件缺漏之處，要明確說出推論依據，不要假裝它已被定義。
- 如果問題其實是實作問題，而不是架構問題，應指出需要搭配 `feature-implementation`。

## 與其他 Skills 的關係

- `contributing`
  用於協作流程、環境設定、Git workflow、smoke test，不負責全局架構理解。

- `feature-implementation`
  用於實作、重構與程式碼修改。當需要判斷功能落點或模組邊界時，先用本 skill 建立架構判準，再進入實作。

- `skill-creator`
  用於建立與維護 canonical skills。本 skill 可協助判斷 AI 層文件與專案技術架構之間的分工。

## 資料來源優先順序

1. 實際 repo 結構與程式碼
2. `docs/project_architecture.md`
3. `docs/technical_rationale.md`
4. `docs/uml/`
5. 其他輔助文件

說明：

- 架構文件是高優先參考，但不是唯一真相。
- 若文件與實作衝突，應明確指出衝突，不應只照文件回答。

## 驗證

- 回答架構問題時，至少交叉檢查 `docs/project_architecture.md` 與實際目錄結構。
- 若回答模組落點問題，至少再檢查一次 `src/block2python/` 的現有子模組。
- 若問題涉及 AI skills 層，至少再檢查 `.agent/` 與相關技能文件。

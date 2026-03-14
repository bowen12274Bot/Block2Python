---
name: game-product-direction
description: 理解並說明 Block2Python 目前已確立的遊戲產品定位、主流程、關卡分工與核心玩法規則。用於回答遊戲方向、產品定位、主線/支線/示範關/練習關如何分工，或整理目前已採納的 game-first 方向時。不要用於技術架構設計或未定規劃討論。
---

# Game Product Direction

使用此 skill 來建立對 Block2Python 已確立遊戲產品方向的理解。

## 目標

- 說明目前已採納的產品定位與 game-first 方向
- 說明主流程、關卡分工與核心玩法規則
- 作為人類與 AI 共讀的產品方向導讀入口
- 避免把未定事項、草案或技術架構內容混入回答

## 先讀

1. [`docs/project_plan.md`](../../../docs/project_plan.md)
2. [`docs/product/chapter_design.md`](../../../docs/product/chapter_design.md)
3. 必要時補讀 [`docs/requirements.md`](../../../docs/requirements.md) 的產品需求部分

## 回答原則

- 只根據目前已確立、已寫入正式文件的內容回答。
- 優先以 `docs/project_plan.md` 與 `docs/product/` 文件為準。
- 若文件中某項內容尚未定案、仍在待補或只存在於規劃文件，不要把它講成既定事實。
- 如果問題本質上是技術架構、模組分層或實作落點，改用 `project-architecture`。

## 適合回答的內容

- 這個遊戲目前的產品定位是什麼
- game-first 方向下，程式關卡在主流程中的角色
- 主線、支線、示範關、支線練習關的分工
- 工具包與電池能量等核心玩法規則
- 玩家在遊戲中的標準流程與節奏

## 不負責的內容

- 技術架構設計
- Godot / PySide6 / challenge core 分層判斷
- 未定產品方向的延伸討論
- 細部故事設定與角色背景

## 與其他 Skills 的關係

- `game-story-background`
  用於世界觀、角色、反派與敘事背景理解。

- `project-architecture`
  用於技術架構、模組責任與功能落點判斷。

- `development-planning`
  用於判斷是否需要先撰寫計畫文件。

---
name: game-story-background
description: 理解並說明 Block2Python 目前已確立的遊戲世界觀、故事前提、角色關係與敘事調性。用於回答遊戲劇情背景、世界觀設定、主要角色與故事 premise，或讓 AI 先建立共讀的故事背景理解時。不要用於技術架構設計或玩法規則判斷。
---

# Game Story Background

使用此 skill 來建立對 Block2Python 已確立故事背景的理解。

## 目標

- 說明目前已採納的世界觀、故事前提與角色關係
- 協助人類與 AI 共讀同一份故事背景文件
- 避免把未定劇情細節或產品規則混入背景說明

## 先讀

1. [`docs/product/worldbuilding.md`](../../../docs/product/worldbuilding.md)
2. 必要時補讀 [`docs/project_plan.md`](../../../docs/project_plan.md) 的核心背景段落

## 回答原則

- 只根據目前已確立、已寫入正式文件的故事背景回答。
- 優先以 `docs/product/worldbuilding.md` 為主，必要時再用 `docs/project_plan.md` 補充。
- 若某個角色、章節或城市內容仍未定案，不要自行腦補。
- 如果問題本質上是玩法定位、關卡結構或產品分工，改用 `game-product-direction`。

## 適合回答的內容

- 遊戲世界觀與故事 premise
- 玩家、Byte、Bug King 的基礎定位
- 故事調性與敘事方向
- Code Planet 與城市失控的背景前提

## 不負責的內容

- 技術架構設計
- 關卡規則與產品玩法分工
- 尚未定案的劇情細節延伸
- 主線/支線的產品節奏設計

## 與其他 Skills 的關係

- `game-product-direction`
  用於產品定位、主流程與玩法規則理解。

- `project-architecture`
  用於技術架構、模組分層與系統責任判斷。

# .agent Overview

`.agent/` 是 Block2Python 專案中所有 agent skills 的唯一 canonical source。

本目錄的角色是集中維護可供多個 AI 模型共用的 skills。`.agents/`、`.claude/`、`.codex/` 是不同模型的入口層，不是 skill 來源，也不應在那些目錄中維護另一份 skill 內容。

## 人類文件層與 AI 工作層

本專案的知識來源分成兩層：

- 人類文件層：`docs/`
  主要給人閱讀，負責完整說明背景、需求、架構、規格、計畫與協作規範。

- AI 工作層：`.agent/skills/`
  主要給 AI 使用，負責告訴模型該讀哪些文件、先讀什麼、如何建立上下文、如何判斷與執行任務。

這代表專案不需要把 `docs/` 全部改寫成 AI 專用文件；比較合理的做法是讓 skills 正確引導 AI 使用既有文件。

## 使用原則

- `docs/` 仍然是主要內容來源，不應把完整知識複製進 skills。
- skill 的工作是觸發、導讀、建立決策框架與執行流程，而不是重寫一份新的文件系統。
- 當文件與實際 repo 結構不一致時，AI 應指出差異，而不是只背文件內容。
- 對 AI 重要的文件應盡量保持章節清楚、責任單一、容易索引。

## 結構

```text
.agent/
  README.md
  SKILLS.md
  skills/
    contributing/
    development-planning/
    feature-implementation/
    project-architecture/
    skill-creator/
```

## 文件分工

- `README.md`
  說明 `.agent` 的角色、原則與和其他目錄的關係。

- `SKILLS.md`
  作為目前 skills 的人工維護索引，提供快速導覽與用途摘要。
  這份文件不是 source of truth；真正的技能定義仍以各 skill 的 `SKILL.md` 為準。

## 維護原則

- 新增或修改 skill 時，只編輯 `.agent/skills/<skill-name>/`。
- skill 的 `SKILL.md` 是主要入口，`scripts/`、`references/`、`assets/` 依需求加入。
- 不要在 `.agents/`、`.claude/`、`.codex/` 中建立另一份 skill 內容。
- 若 skills 清單有變動，應同步更新 `.agent/SKILLS.md`。

## 與其他目錄的關係

- `docs/project_architecture.md`
  說明專案與 skills 的整體架構原則。

- `.agents/`、`.claude/`、`.codex/`
  作為不同 AI 模型的入口層，應連到這裡的 canonical skills。

- `skills-lock.json`
  記錄已安裝或已鎖定的 skill 來源與 hash。

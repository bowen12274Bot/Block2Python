---
name: skill-creator
description: 建立或更新 Agent Skills。用於設計、規劃、結構化、驗證或封裝 skills，特別是需要處理 scripts、references、assets 與 SKILL.md 結構時。
---

# Skill Creator

使用此 skill 來建立或調整可重用的 agent skill。
在 Block2Python 專案中，`.agent/skills/` 是唯一的 skill 來源；`.agents/`、`.claude/`、`.codex/` 只是不同模型的入口，不是 skill source。

## Skills 是什麼

Skill 是模組化、可自含的能力包，用來補足模型本身不會穩定記住的流程知識、領域知識與工具使用方式。可以把它視為某個主題的操作手冊，讓 agent 在特定任務上更穩定、更可控。

### Skill 提供的價值

1. 專用工作流程：把多步驟流程固定下來。
2. 工具整合說明：告訴 agent 如何使用特定腳本、格式或 API。
3. 領域知識：保存專案或團隊特有的規則、結構與慣例。
4. 可重用資源：把 scripts、references、assets 綁在 skill 內一起交付。

## 核心原則

### 內容要精簡

Context window 是共享資源。Skill 會和系統提示、對話歷史、其他 skills 的 metadata，以及使用者當前需求一起競爭上下文。

預設模型已經足夠聰明，只補它不知道或不穩定知道的內容。

### 控制自由度

依照任務的脆弱程度與變異程度，決定 skill 要給多強的約束：

- 高自由度：使用文字原則與 heuristics，適合多種做法都合理的任務。
- 中自由度：使用偽代碼、步驟框架或可配置腳本，適合有推薦模式但可接受變形的任務。
- 低自由度：使用固定腳本、少量參數與嚴格順序，適合容易出錯且需要高一致性的任務。

## Skill 的基本結構

每個 skill 至少要有一個 `SKILL.md`，其餘資源依需求增加：

```text
skill-name/
  SKILL.md
  scripts/
  references/
  assets/
```

### `SKILL.md`

`SKILL.md` 由兩部分組成：

- Frontmatter：至少包含 `name` 與 `description`
- Body：skill 真正的操作說明

注意：skill 是否被觸發，主要看 frontmatter 的 `description`。因此「何時該用這個 skill」要寫在 `description`，不要只寫在 body。

## Block2Python 專案特有行為

- `scripts/init_skill.py` 預設輸出到 `.agent/skills/`
- 新 skill 只建立 canonical 版本，不會自動寫入 `.agents/`、`.claude/`、`.codex/`
- `.agents/`、`.claude/`、`.codex/` 是不同模型的入口層，不是 skill 來源
- 新增、刪除或重新命名 skill 後，應同步更新 [`.agent/SKILLS.md`](../../../.agent/SKILLS.md)
- 新 skill 模板會帶入本專案慣用的中文章節骨架

## 建立 Skill 的流程

1. 先理解 skill 會如何被使用，最好有具體例子。
2. 盤點哪些內容應抽成可重用資源，例如 scripts、references、assets。
3. 用 `scripts/init_skill.py` 初始化 skill 骨架。
4. 編寫 `SKILL.md` 與必要資源。
5. 更新 [`.agent/SKILLS.md`](../../../.agent/SKILLS.md)。
6. 用 `scripts/package_skill.py` 封裝前先驗證。
7. 根據實際使用情況迭代。

### 命名規則

- skill 名稱只使用小寫英文字母、數字與連字號
- 使用 hyphen-case，例如 `plan-mode`
- 名稱長度控制在 64 字元內
- 資料夾名稱要與 skill 名稱完全一致

## 實作建議

### 先從可重用資源開始

如果工作流程中有穩定重複出現的腳本、模板或參考資料，先把它們整理出來，再回頭寫 `SKILL.md`，通常會更清楚。

### `description` 要寫得可觸發

`description` 不是摘要而已，它也是 skill 的觸發條件說明。要同時包含：

- 這個 skill 能做什麼
- 哪些任務、情境或檔案型別會觸發它

### 指令與腳本要可驗證

如果你在 skill 內加了腳本，應實際執行至少一組代表性案例，不要只假設它會動。

### 用 reference 承接長內容

當 `SKILL.md` 開始變長，就把細節拆到 `references/`，保留主檔作為導航與執行框架。

## 封裝與驗證

完成後使用下列腳本：

```bash
scripts/package_skill.py <path/to/skill-folder>
```

封裝前會自動驗證 skill 結構，包括 frontmatter、命名規則與檔案組織。

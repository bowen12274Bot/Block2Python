# 開發工作流程

- 文件版本：0.1.0
- 更新日期：2026-03-08

本文件整理 Git 工作流程、commit / PR 準則、驗證方式，以及 Definition of Done。

## 1. 分支策略

- 預設分支：`main`
- `main` 應保持可整合、可展示、可回退的狀態
- 正式變更原則上都從 `main` 開新分支，不直接在 `main` 上提交
- `docs/` 與 `.agent/skills/` 的調整也視為正式變更

建議命名：

- 功能開發：`feature/<topic>`
- 修 bug：`fix/<topic>`
- 文件：`docs/<topic>`
- 雜項或重構：`chore/<topic>`、`refactor/<topic>`

## 2. 建議開發流程

```text
從 main 建立分支 -> 在分支上修改 -> 自行驗證 -> 整理 commit -> 開 PR -> 合併回 main
```

工作原則：

- 每個分支盡量聚焦單一主題
- 若途中變成另一件事，應另開分支，不要把不同目的塞進同一個 PR
- 若只是本地草稿或臨時測試，可先不提交；一旦要進 Git 歷史，就整理成正式分支

## 3. Commit 訊息

建議採用接近 Conventional Commits 的寫法：

- 格式：`<type>(<scope>): <summary>` 或 `type: summary`
- `type` 建議：`feat` / `fix` / `docs` / `chore` / `refactor` / `test`
- `summary` 應描述做了什麼，而不是怎麼做
- 建議 72 字元內，並盡量用動詞開頭

範例：

```text
feat(ui): add block workspace toolbar
fix(progress): persist last_opened_level
docs: clarify Notion vs GitHub source of truth
refactor(levels): extract loader to module
chore: bump PySide6 version
```

## 4. 改動規模與歷史整理

是否要 squash 後再 PR，取決於這次改動的可追溯性需求。

### 4.1 小改動

- 影響 1 到 3 個檔案
- 單一目的
- 不涉及架構邊界或流程設計

建議：

- 整理成 1 筆 squash commit
- PR 描述簡短即可

### 4.2 中改動

- 影響約 3 到 10 個檔案
- 仍是單一主題，但有數個子項
- 需要補充背景與原因

建議：

- 可整理成 1 筆 squash commit
- 若內含不同性質的修改，可保留 2 到 3 筆有語意的 commit
- PR 描述要交代背景、範圍與驗證方式

### 4.3 大改動

- 影響超過 10 個檔案，或跨多個模組 / 目錄
- 涉及架構、工具鏈、工作流程或核心決策
- 未來可能需要回頭追原因，或局部回退

建議：

- 優先保留 2 到 4 筆有語意的 commit
- 若最後仍決定 squash，PR 描述必須能補足過程資訊

## 5. PR / Review

- 以 PR 合併到 `main`
- PR 描述至少包含：
  - 做了什麼
  - 為什麼這樣做
  - 如何驗證
- 若 PR 經過 squash，描述中應補上整理後的重點與驗證結果
- 若 PR 涉及 `docs/`、`.agent/skills/` 或工作流程規則，應說明對團隊協作的影響
- 若有 Notion 任務，建議在 PR 描述附上對應連結或 ID

## 6. 合併與回退

- 小改動可接受 squash merge
- 中改動可依內容選擇 squash merge 或保留少量語意化 commit
- 大改動不建議壓到只剩 1 筆 commit，除非 PR 已完整保存決策脈絡
- 若要撤回已合併變更，優先使用 `git revert`，避免改寫 `main` 歷史

## 7. 最小驗證

至少擇一執行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

若改動會影響 UI，優先跑 `tools/run_ui.ps1`。

## 8. Definition of Done（建議）

任務要標記為完成，至少符合：

- 有對應 PR 並已合併到 `main`
- 至少跑過一次 smoke test（CLI 或 UI 擇一）
- 若任務影響 UI，優先提供 UI 驗證結果
- 若有 Notion 任務卡，已貼上對應的 PR 或 commit
- 任務或 PR 描述中有簡短的驗證結論

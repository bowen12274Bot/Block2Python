# 貢獻指南

- 文件版本：0.2.3
- 更新日期：2026-03-06

本專案以 Demo 展示為優先，開發期先確保「所有人可以用同一套 Python 環境啟動」。

## 0. 快速開始

> 目標：用最短步驟把專案跑起來（CLI / UI）；環境與 Blockly 的完整說明分別見第 2 章與第 3 章。

### 0.1 取得原始碼

```powershell
git clone <REPO_URL>
cd Block2Python
```

### 0.2 建立開發環境（一次性）

詳細環境規則、依賴管理與注意事項見第 2 章。

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
```

### 0.3 下載並 vendor Blockly dist（必要）

本專案 UI 需要 Blockly dist 靜態檔才能正常運作，因此 **下載並 vendor Blockly dist 是必要動作**。下載與匯入方式見第 3 章。

### 0.4 跑起來（smoke test）

完成環境初始化與 Blockly vendor 後，再執行以下命令確認專案可啟動：

- CLI Demo：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
```

- UI：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

## 1. 任務與排程（Notion）

本專案使用 Notion 作為「手動排程」工具：每位成員都可以在任務表自行修改、補充欄位與內容，**任務表不強制格式**。

- 加入方式：請向維護者索取 Notion workspace 使用權限。
- Notion 官網：<https://www.notion.com/zh-tw>
- 使用原則：
  - 任務即時狀態以 Notion 為準（例如 `未開始` / `進行中` / `已完成`）。
  - 具體實作進度以 GitHub commit 為準（commit/PR 內容代表實際完成的變更）。
  - 建議先在 `docs/development_plans/` 做好規劃（方案、取捨、驗證方式），再把文件連結貼到 Notion 任務卡，方便版本化與 review。

### 1.1 Notion 任務卡（自由格式；可選建議）

任務可以想到什麼就加什麼；若想讓任務更好追蹤，可考慮加入以下欄位：

- Title：任務名稱
- Owner：主要負責人/協作者
- Status：例如 `未開始` / `進行中` / `已完成`
- 優先順序：`低` / `中` / `高`
- 到期日：預期完成時間
- 說明/備註：如何做、為什麼做、預期結果、阻塞點
- 計畫文件：`docs/development_plans/` 相關文件
- GitHub 連結：PR / commits（用來對齊實作進度）

## 2. 開發環境（標準：`.venv`）

本專案 **一律以 repo 根目錄的 `.venv` 當標準 Python 環境**（避免系統 Python / MSYS2 Python / Conda 混用導致套件找不到）。

先決條件：

- Windows PowerShell
- Windows Python Launcher（`py` 指令可用）

### 2.1 一次性初始化

在 repo 根目錄執行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
```

### 2.2 啟動（CLI Demo）

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
```

### 2.3 啟動（UI）

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

若看到「Missing .venv」，先跑 `tools/setup_dev_env.ps1`。

### 2.4 依賴管理（目前方式）

目前依賴由 `tools/setup_dev_env.ps1` 統一安裝到 `.venv`。

- 若新增第三方套件：請同步更新 `tools/setup_dev_env.ps1`，讓其他人可一鍵重建環境。

## 3. Blockly dist

本專案採用 `QWebEngineView` 內嵌 Web 方式承載 Blockly。 Blockly dist 靜態檔是積木 UI 的必要依
賴，需要從外部下載檔案，可從以下三種方式選擇一種方式下載；執行ps指令後會自動加入 `assets/blockly/vendor/`。

### 3.1 從網路下載（URL）

```powershell
$env:BLOCKLY_DIST_URL = "https://github.com/RaspberryPiFoundation/blockly/releases/download/blockly-v12.4.1/blockly-12.4.1.tgz"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

### 3.2 從本機 zip 匯入 (下載 zip 並複製檔案位置)

```powershell
$env:BLOCKLY_DIST_ZIP = "C:\\path\\to\\blockly_dist.zip"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

### 3.3 從解壓後資料夾匯入（放入.block2python\中）

```powershell
$env:BLOCKLY_DIST_DIR = ".block2python\\blockly-12.4.1\\package"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly_from_dir.ps1
```

### 3.4 為什麼 `assets/blockly/vendor/` 不進版控

本專案將 `assets/blockly/vendor/` 設為不進版控（避免 repo 變大）。因此每位開發者在第一次跑 UI 前都需要執行一次 vendor 流程，讓 UI 能載入 Blockly dist。

## 4. 本機資料（進度保存）

本機進度會寫入：

- `.block2python/progress.json`

此資料夾已被 `.gitignore` 忽略，不會進版控。

### 4.1 `.block2python/` 的定位（不進版控）

`.block2python/` 是本專案的「本機狀態 / 暫存區」，用途類似：

- 建置或下載的暫存（可重建）
- 每個人/每台機器不同的執行期資料（不應進 Git）

目前我們放的內容包含：

- `progress.json`：關卡進度（執行期狀態）
- `blockly_dist.zip`、`blockly_dist_tmp/` 等：工具腳本下載與解壓的暫存
- `.block2python/blockly-12.4.1/`：你手動下載/解壓的 Blockly dist 來源資料（**來源暫存**，可刪）

### 4.2 重置進度

```powershell
powershell -ExecutionPolicy Bypass -File tools/reset_progress.ps1
```

## 5. Git 工作流程

本專案以 Demo 推進為主，流程以「小步快跑、可回溯、好整合」為原則。

### 5.1 分支命名（建議規則）

- 預設分支：`main`
- 功能開發：`feature/<topic>`
- 修 bug：`fix/<topic>`
- 文件：`docs/<topic>`
- 雜項/重構：`chore/<topic>`、`refactor/<topic>`

`<topic>` 建議用短字串（例如 `ui-shell`、`levels-loader`、`progress-store`）。

### 5.2 Commit 訊息（建議寫法）

建議採用類似 Conventional Commits 的寫法，讓歷史更好搜尋與回溯：

- 格式：`<type>(<scope>): <summary>` 或 `type: summary`
- `type` 建議：`feat` / `fix` / `docs` / `chore` / `refactor` / `test`
- `summary` 建議：
  - 一行講清楚改了什麼（偏「做了什麼」，不是「怎麼做」）
  - 盡量短（建議 72 字元內）
  - 用動詞開頭（例如「新增」「修正」「調整」「移除」）
- 若要對齊 Notion 任務：可在 commit message 末尾加上 Notion 任務 ID/關鍵字，或在 commit body 貼 Notion 連結（不強制）

範例：

```text
feat(ui): add block workspace toolbar
fix(progress): persist last_opened_level
docs: clarify Notion vs GitHub source of truth
refactor(levels): extract loader to module (notion: Sprint3-Levels)
chore: bump PySide6 version
```

### 5.3 PR / Review 規則（建議規則，不強制）

- 以 PR 合併到 `main`（避免直接推 `main`）
- PR 描述至少包含：
  - 做了什麼、為什麼做
  - 如何驗證（至少貼上你跑過的命令）
- 每個 PR 盡量聚焦單一主題，避免「大雜燴」難 review
- PR 建議要對應 Notion 任務卡（在 PR description 貼上 Notion 任務連結或 ID）

### 5.4 合併與回溯（建議規則）

- 合併策略：以「可追溯、可回滾」為優先
- 回溯策略：若要撤回已合併變更，優先使用 `git revert` 產生反向提交（避免改寫 `main` 歷史）

### 5.5 最小驗證（建議擇一或兩個）

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

## 6. 開發計畫文件（`docs/development_plans/`）

建議先寫開發計畫，再開始實作。特別是當任務牽涉選型、資料格式、跨模組流程、教學/劇情設計或 AI 策略時，先寫計畫可以降低返工與溝通成本。

`docs/development_plans/` 用來存放較完整的主題規劃，例如技術引入、Judge 選型、Blockly 範圍、教學/劇情流程或 AI 助教策略。

### 6.1 什麼時候應該新增計畫文件

- 任務已經超過單一 PR 可以講清楚的範圍
- 需要先比較方案、列風險、定義 DoD
- 需要跨人協作，且希望 Notion 之外有可版本化的規劃內容

### 6.2 計畫文件建議內容

- 目標與不做什麼（Scope / Non-goals）
- DoD（怎樣算完成）
- 引入順序與驗證方式（手動/自動）
- 風險與替代方案（若選型未定，先 stub）

### 6.3 檔名規則（建議）

- 採用「主題優先，日期輔助」原則：
  - 優先用主題命名，讓人能直接依內容找到文件
  - 日期只用在需要保留快照時，不作為預設命名方式
- 檔名使用 `snake_case`
- 主計畫建議格式：
  - `<topic>_plan.md`
  - 例如：`technical_introduction_plan.md`
  - 例如：`blockly_vendor_plan.md`
  - 例如：`progress_store_plan.md`
- 驗證/盤點文件建議格式：
  - `<topic>_plan_verification.md`
  - 例如：`technical_introduction_plan_verification.md`
- 回顧/結案文件建議格式：
  - `<topic>_plan_review.md`
  - 例如：`progress_store_plan_review.md`
- 若同一主題需要保留某個時間點的決策快照，再加日期：
  - `<topic>_plan_YYYY_MM_DD.md`
  - 例如：`ui_shell_plan_2026_03_06.md`

### 6.4 管理原則（建議）

- 一個主題原則上只保留一份主計畫檔
- 小幅更新直接改原檔，不另外複製新版本
- 只有在需要保留當下決策、準備比較版本、或重要方案轉折時，才建立日期快照檔
- 若計畫已完成，可在文件開頭標記狀態（例如 `Status: done`），不必急著搬移或封存
- 若有 Notion 任務，建議把 `docs/development_plans/` 的文件連結貼回任務卡，讓 Notion 負責追蹤狀態、文件負責保存規劃內容

### 6.5 何時用日期，何時不要用日期

- 用日期：
  - 同一主題短時間內有明顯版本差異，且需要保留決策過程
  - 要提交某個階段性方案，之後可能再重寫
  - 要和會議結論、里程碑審查版本對齊
- 不用日期：
  - 只是一般補充、修正文句、更新待辦順序
  - 同一主題仍然只有一份有效規劃
  - 沒有保留歷史快照的需求

## 7. 代碼規範（最低一致性）

目前不強制綁定特定 formatter/linter（等初期建立階段結束再收斂工具鏈），但請遵守以下最低一致性：

### 7.1 命名與結構

- 模組分層以 `src/block2python/` 為主（參考 `src/README.md`）
- 跨層交換資料一律走 `src/block2python/contracts/`（避免 UI/Judge/Analysis 互相直連內部結構）
- 允許先用 stub（`StubJudge`/`StubAnalyzer`）打通流程，但需保留可替換介面（Protocol）

### 7.2 Python 風格（最低規範）

- 盡量加上 type hints（尤其是跨模組介面與資料結構）
- 避免在 import 時做副作用（I/O、讀檔、初始化全域狀態）
- 優先使用 `pathlib.Path` 處理路徑
- 檔案編碼以 UTF-8 為主（JSON/Markdown 皆同）

## 8. 測試與驗證（先用 smoke test）

目前尚未建立正式測試框架（例如 pytest），先以「可重複的 smoke test」確保 Demo 流程不壞。

### 8.1 如何跑（smoke test）

- CLI：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
```

- UI：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

### 8.2 Definition of Done（建議）

一張 Notion 任務要標記為 `已完成`，至少符合：

- Notion 任務卡已貼上對應的 GitHub PR / commits（用來對齊「實作進度以 commit 為準」）
- 有對應 PR 並已合併到 `main`
- 至少跑過一次 smoke test（CLI 或 UI 擇一；若任務影響 UI，優先跑 UI）
- 任務卡上有「如何驗證」與結果（例如貼上執行命令與簡短結論）

### 8.3 如何新增（目前建議）

- 若你新增的是純邏輯（例如 levels loader / progress store / contracts）：優先寫成可直接用 Python 呼叫的函式，方便後續補測試。
- 若需先補最小測試：建議先在 `tests/` 放「可重複執行的腳本/測試檔」，等團隊決定導入 pytest 後再統一搬移與收斂。

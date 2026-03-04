# 貢獻指南（Demo）

本專案以 Demo 展示為優先，開發期先確保「所有人可以用同一套 Python 環境啟動」。

## 1. 開發環境（標準：`.venv`）

本專案 **一律以 repo 根目錄的 `.venv` 當標準 Python 環境**（避免系統 Python / MSYS2 Python / Conda 混用導致套件找不到）。

先決條件：

- Windows PowerShell
- Windows Python Launcher（`py` 指令可用）

### 1.1 一次性初始化

在 repo 根目錄執行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
```

此腳本會：

- 建立 `.venv`
- 用 `.venv` 安裝依賴（目前包含 `PySide6`）

### 1.2 啟動（CLI Demo）

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
```

### 1.3 啟動（UI）

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

若看到「Missing .venv」，先跑 `tools/setup_dev_env.ps1`。

### 1.4 Blockly 靜態檔（Vendor）

本專案採用 `QWebEngineView` 內嵌 Web 方式承載 Blockly。Demo 建立期可先用 placeholder（仍可測 Web↔Desktop 橋接）；若要啟用真正 Blockly workspace，需把 Blockly dist 靜態檔放到 `assets/blockly/vendor/`。

取得方式（需網路；URL 由團隊自行決定版本來源）：

```powershell
$env:BLOCKLY_DIST_URL = "https://github.com/RaspberryPiFoundation/blockly/releases/download/blockly-v12.4.1/blockly-12.4.1.tgz"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

完成後重新啟動 UI。

若你是手動下載 zip（推薦），可改用本機路徑：

```powershell
$env:BLOCKLY_DIST_ZIP = "C:\\path\\to\\blockly_dist.zip"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

若你已經有「解壓後的 dist 資料夾」（裡面直接包含 `blockly_compressed.js` 等檔案），可用目錄方式 vendor：

```powershell
$env:BLOCKLY_DIST_DIR = ".block2python\\blockly-12.4.1\\package"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly_from_dir.ps1
```

## 2. 本機資料（進度保存）

本機進度會寫入：

- `.block2python/progress.json`

此資料夾已被 `.gitignore` 忽略，不會進版控。

### 2.1 `.block2python/` 的定位（不進版控）

`.block2python/` 是本專案的「本機狀態 / 暫存區」，用途類似：

- Node 專案的本機狀態（但不等同 `node_modules`）
- 建置或下載的暫存（可重建）
- 每個人/每台機器不同的執行期資料（不應進 Git）

目前我們放的內容包含：

- `progress.json`：關卡進度（執行期狀態）
- `blockly_dist.zip`、`blockly_dist_tmp/` 等：工具腳本下載與解壓的暫存
- `.block2python/blockly-12.4.1/`：你手動下載/解壓的 Blockly dist 來源資料（**來源暫存**，可刪）

注意：

- UI 真正載入的頁面是 `assets/blockly/index.html`；它會引用 `assets/blockly/vendor/` 下的檔案（見下方 2.2）
- `.block2python/` 內的來源資料只用來「拷貝/匯入」到 `assets/blockly/vendor/`，不是 UI 的直接依賴路徑

### 2.2 Blockly 靜態檔（vendor）為什麼不進版控

本專案目前將 `assets/blockly/vendor/` 設為不進版控（避免 repo 變大）。因此：

- 每位開發者需要自行執行一次 vendor 流程，把 dist 檔放到 `assets/blockly/vendor/`
- 若未 vendor，UI 仍可用 placeholder 模式（用於驗證 Web↔Desktop 橋接）

重置進度：

```powershell
powershell -ExecutionPolicy Bypass -File tools/reset_progress.ps1
```

## 3. 分支與流程（TBD）

本專案以 Demo 推進為主，流程以「小步快跑、可回溯、好整合」為原則。

### 3.1 分支命名（建議規則）

- 預設分支：`main`
- 功能開發：`feature/<topic>`
- 修 bug：`fix/<topic>`
- 文件：`docs/<topic>`
- 雜項/重構：`chore/<topic>`、`refactor/<topic>`

`<topic>` 建議用短字串（例如 `ui-shell`、`levels-loader`、`progress-store`）。

### 3.2 PR / Review 規則（建議規則）

- 以 PR 合併到 `main`（避免直接推 `main`）
- PR 描述至少包含：
  - 做了什麼、為什麼做
  - 如何驗證（至少貼上你跑過的命令）
- 每個 PR 盡量聚焦單一主題，避免「大雜燴」難 review

最小驗證建議（擇一或兩個）：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

## 4. 代碼規範（TBD）

目前不強制綁定特定 formatter/linter（等初期建立階段結束再收斂工具鏈），但請遵守以下最低一致性：

### 4.1 命名與結構

- 模組分層以 `src/block2python/` 為主（參考 `src/README.md`）
- 跨層交換資料一律走 `src/block2python/contracts/`（避免 UI/Judge/Analysis 互相直連內部結構）
- 允許先用 stub（`StubJudge`/`StubAnalyzer`）打通流程，但需保留可替換介面（Protocol）

### 4.2 Python 風格（最低規範）

- 盡量加上 type hints（尤其是跨模組介面與資料結構）
- 避免在 import 時做副作用（I/O、讀檔、初始化全域狀態）
- 優先使用 `pathlib.Path` 處理路徑
- 檔案編碼以 UTF-8 為主（JSON/Markdown 皆同）

### 4.3 依賴管理（目前方式）

目前依賴由 `tools/setup_dev_env.ps1` 統一安裝到 `.venv`。

- 若新增第三方套件：請同步更新 `tools/setup_dev_env.ps1`，讓其他人可一鍵重建環境。

## 5. 測試（TBD）

目前尚未建立正式測試框架（例如 pytest），先以「可重複的 smoke test」確保 Demo 流程不壞。

### 5.1 如何跑（smoke test）

- CLI 流程：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
```

- UI 流程：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

### 5.2 如何新增（目前建議）

- 若你新增的是純邏輯（例如 levels loader / progress store / contracts）：優先寫成可直接用 Python 呼叫的函式，方便後續補測試。
- 若需先補最小測試：建議先在 `tests/` 放「可重複執行的腳本/測試檔」，等團隊決定導入 pytest 後再統一搬移與收斂。

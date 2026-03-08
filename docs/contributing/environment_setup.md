# 開發環境與本機資料

- 文件版本：0.1.0
- 更新日期：2026-03-08

本文件整理 Block2Python 的本機開發環境、Blockly vendor 流程，以及不進版控的本機資料。

## 1. Python 開發環境（標準：`.venv`）

本專案一律以 repo 根目錄的 `.venv` 當標準 Python 環境，避免系統 Python、MSYS2 Python、Conda 混用造成套件與執行路徑不一致。

先決條件：

- Windows PowerShell
- Windows Python Launcher（`py` 指令可用）

### 1.1 一次性初始化

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1
```

### 1.2 啟動（CLI Demo）

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
```

### 1.3 啟動（UI）

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
```

若看到 `Missing .venv`，先重新執行 `tools/setup_dev_env.ps1`。

### 1.4 依賴管理

目前依賴由 `tools/setup_dev_env.ps1` 統一安裝到 `.venv`。

- 若新增第三方套件，請同步更新 `tools/setup_dev_env.ps1`
- 避免只在個人電腦手動安裝後就假設其他人也能重現

## 2. Blockly dist

本專案 UI 使用 `QWebEngineView` 承載 Blockly，因此 Blockly dist 靜態檔是必要依賴。執行下列腳本後，檔案會被匯入到 `assets/blockly/vendor/`。

### 2.1 從網路下載（URL）

```powershell
$env:BLOCKLY_DIST_URL = "https://github.com/RaspberryPiFoundation/blockly/releases/download/blockly-v12.4.1/blockly-12.4.1.tgz"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

### 2.2 從本機 zip 匯入

```powershell
$env:BLOCKLY_DIST_ZIP = "C:\\path\\to\\blockly_dist.zip"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1
```

### 2.3 從解壓後資料夾匯入

```powershell
$env:BLOCKLY_DIST_DIR = ".block2python\\blockly-12.4.1\\package"
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly_from_dir.ps1
```

### 2.4 為什麼 `assets/blockly/vendor/` 不進版控

`assets/blockly/vendor/` 不進版控，避免 repo 因外部靜態資源膨脹。因此每位開發者第一次跑 UI 前，都要先完成一次 vendor 流程。

## 3. 本機資料（不進版控）

本機進度與暫存資料會寫入 `.block2python/`。

目前常見內容包含：

- `.block2python/progress.json`：關卡進度
- `blockly_dist.zip`、`blockly_dist_tmp/`：下載與解壓暫存
- `.block2python/blockly-12.4.1/`：手動下載或解壓的 Blockly dist 來源資料

### 3.1 `.block2python/` 的定位

`.block2python/` 是專案的本機狀態與暫存區，用來放：

- 可重建的下載或建置暫存
- 每台機器不同的執行期資料
- 不應進 Git 的個人狀態資料

### 3.2 重置進度

```powershell
powershell -ExecutionPolicy Bypass -File tools/reset_progress.ps1
```

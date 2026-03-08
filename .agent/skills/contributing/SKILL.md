---
name: contributing
description: 說明如何參與 Block2Python 專案。用於開發環境設定、加入專案、執行 demo、vendor Blockly、理解 Git workflow、撰寫 commit message、開 PR、加入新依賴、遵守程式風格或執行 smoke test 時。
---

# Contributing to Block2Python

使用此 skill 處理 Block2Python 的協作、貢獻與開發流程問題。

完整協作指南：[`docs/contributing.md`](../../../docs/contributing.md)

當問題涉及以下主題時，應先讀完整的 `docs/contributing.md`。

## 快速對照

| 主題 | 對應內容 |
|---|---|
| 開發環境設定與初始化 | 開發環境、`.venv`、setup 流程 |
| Blockly dist vendor | Blockly vendoring 流程與相關腳本 |
| Git workflow | branch、commit、PR、review |
| 開發規範 | 程式風格、依賴管理、協作規則 |
| 驗證流程 | smoke test、Definition of Done |
| 開發計畫文件 | `docs/development_plans/` 的使用方式 |

## 核心命令（Windows PowerShell）

```powershell
# 建立開發環境
powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1

# vendor Blockly
$env:BLOCKLY_DIST_URL = "https://..."
powershell -ExecutionPolicy Bypass -File tools/vendor_blockly.ps1

# 執行 smoke test
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1  # CLI
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1    # UI
```

## 使用原則

- 問題如果屬於「怎麼加入專案、怎麼操作流程、怎麼遵守規範」，使用此 skill。
- 問題如果屬於「系統怎麼分層、功能該放哪裡」，改用 `project-architecture`。
- 問題如果屬於「實際要怎麼改程式」，改用 `feature-implementation`。
- 如果是開始實作前要判斷是否需要計畫文件，改用 `development-planning`。

## 注意事項

- Python 開發環境以 repo 內的 `.venv` 為主。
- `assets/blockly/vendor/` 是 Blockly dist 的目標位置，不應手動隨意變更來源。
- `.block2python/` 屬於本機執行期狀態，不應納入版控。
- 若 setup 或執行流程失敗，優先回頭檢查 `tools/` 內的既有腳本與 `docs/contributing.md`。

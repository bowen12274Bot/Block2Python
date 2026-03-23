---
name: common-troubleshooting
description: 排查 Block2Python 專案中的常見開發問題，例如測試執行失敗、Windows temp 權限、git add 或 commit 在 sandbox 下寫入失敗、PowerShell 指令相容性，以及根目錄快取殘留。當需求涉及「這個 repo 為什麼跑不起來」、「這個錯誤之前怎麼解」、「要用這個 repo 的慣例方式排錯」時使用。
---

# Common Troubleshooting

先判斷問題類型，再讀對應 reference，不要一次把所有經驗都載入。

## 使用方式

1. 先確認錯誤屬於哪一類：
   - 測試執行
   - git / commit
   - PowerShell 指令
   - 編碼與顯示
   - 快取與 temp 殘留
2. 讀 `references/` 中對應檔案。
3. 優先用 repo 既有正式入口重試，不要先自行發明新流程。
4. 若錯誤更像 sandbox / 權限問題，先驗證執行環境，不要直接判定成程式邏輯錯誤。

## 核心原則

- 先分辨是程式邏輯錯誤還是執行環境錯誤。
- 優先沿用 repo 現有工具腳本與入口。
- 若問題是 repo-specific 慣例，應明確說出慣例，不要只給通用建議。
- 修完後要檢查副作用是否也被清掉，例如根目錄快取或壞掉的 temp 路徑。

## 優先使用的正式入口

- 測試：`powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1`
- CLI demo：`powershell -ExecutionPolicy Bypass -File tools/legacy/run_cli_demo.ps1`
- GameSession demo：`powershell -ExecutionPolicy Bypass -File tools/run_game_session_demo.ps1`

## 何時讀哪份 reference

- 測試執行、pytest、coverage、temp 權限：`references/testing-issues.md`
- git add / git commit、sandbox 寫入失敗：`references/git-issues.md`
- PowerShell 指令相容性與命令串接：`references/powershell-issues.md`
- UTF-8、BOM、PowerShell 顯示亂碼、validator 因編碼失敗：`references/encoding-issues.md`
- 根目錄快取、temp 殘留與收尾檢查：`references/cache-and-temp-cleanup.md`

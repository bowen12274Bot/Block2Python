---
name: encoding-safe-writes
description: 用於修正亂碼、避免 PowerShell 寫檔造成編碼損壞，並在這個 repository 內安全地以 UTF-8 寫入文字檔。當中文內容顯示異常、從 PowerShell 編輯 Markdown 或 skill 檔、使用 Set-Content 或 heredoc 可能改變編碼，或需要驗證檔案位元組是否正確時使用。
---

# Encoding Safe Writes

當這個 repo 裡的檔案出現亂碼、PowerShell 寫檔可能產生 Big5/UTF-16/BOM 問題，或你需要確認文字檔已安全地存成 UTF-8 時，使用這個 skill。

## 工作流程

1. 在編輯前先診斷檔案。
   - 用 `Get-Content <file> -Encoding utf8` 讀取文字。
   - 當顯示內容可疑時，用 `Format-Hex <file>` 檢查位元組。

2. 如果目標檔案是 repo 內的一般文字檔，就把它正規化成 UTF-8。
   - 這個 repo 的 Markdown、skills、scripts、docs 優先使用無 BOM 的 UTF-8。
   - 不要依賴 PowerShell 的預設編碼。

3. 從 PowerShell 寫檔時，使用無 BOM 的 .NET writer。
   - 先組好最終完整內容。
   - 用 `[System.IO.File]::WriteAllText(..., $utf8NoBom)` 寫入。
   - 標準片段見 `references/powershell-utf8.md`。

4. 每次寫入後都驗證。
   - 用 `Get-Content -Encoding utf8` 重新讀取。
   - 用 `Format-Hex` 再檢查一次前幾個位元組。
   - 確認顯示出來的是正常中文，不是亂碼。

## 規則

- repo 內的文字檔預設視為 UTF-8，除非有很強的理由不要這樣做。
- 避免使用沒有明確編碼策略的 `Set-Content`。
- 如果必須用 PowerShell 手動重寫文字檔，優先使用 .NET 的 UTF-8 無 BOM writer，不要依賴 shell 預設值。
- 如果檔案內容已經損壞，直接用正確的 UTF-8 全量重寫，不要試著保留錯誤位元組。

## 參考資料

- 標準的 PowerShell 寫檔與驗證指令，見 `references/powershell-utf8.md`。

# 編碼與顯示問題

## 常見症狀

- PowerShell `Get-Content` 顯示中文亂碼
- 檔案內容看起來正常，但 validator 報 frontmatter 格式錯誤
- `SKILL.md` 明明有 `---`，仍被判定 YAML frontmatter 無效
- 寫入中文後，後續工具讀到奇怪字元或 BOM

## 常見原因

- 用 PowerShell 預設編碼重寫 UTF-8 檔案
- 使用帶 BOM 的 UTF-8，導致某些工具解析失敗
- 終端顯示編碼和檔案實際編碼不同
- 把 shell 指令殘留內容誤寫進檔案

## 這個 repo 的實務解法

1. 先分辨是「顯示亂碼」還是「檔案真的壞掉」
2. 若 validator 失敗，優先懷疑檔案實際內容或 BOM，而不是只看終端輸出
3. 對 skill / markdown 這類文字檔，優先使用 UTF-8 無 BOM
4. 重寫檔案後，立刻重新讀一次檔案內容並跑 validator

## PowerShell 重寫 UTF-8 無 BOM

在這個 repo，如果 `Set-Content -Encoding utf8` 導致問題，可改用 .NET 明確寫 UTF-8 無 BOM：

```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

## 驗證方式

- 重新 `Get-Content <file> -Encoding utf8`
- 重新跑對應 validator
- 不要只因為終端亂碼就判定檔案一定損壞

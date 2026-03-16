# PowerShell UTF-8 寫檔模式

當你需要在這個 repo 裡用 PowerShell 重寫文字檔時，使用這個模式。

```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$content = @'
...final text...
'@
[System.IO.File]::WriteAllText((Resolve-Path $path), $content, $utf8NoBom)
```

## 驗證方式

以 UTF-8 讀回：

```powershell
Get-Content <file> -Encoding utf8
```

檢查位元組：

```powershell
Format-Hex <file> | Select-Object -First 12
```

## 注意事項

- `Set-Content` 可能跟隨 host 預設值，或產生你沒有預期的編碼。
- CJK 文字的 UTF-8 位元組通常會出現像 `E4`、`E5`、`E6`、`E7`、`E8`、`E9` 這類開頭，而不是舊式 Big5 位元組樣式。
- 如果存檔後仍然是亂碼，先檢查位元組，不要直接把終端畫面當成唯一真相。

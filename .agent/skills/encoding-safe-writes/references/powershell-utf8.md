# PowerShell UTF-8 Safe Patterns

Use these patterns when editing files that may contain Chinese or other non-ASCII text.

## 1. Preferred: Python UTF-8 write

```powershell
python -c "from pathlib import Path; Path('README.md').write_text(content, encoding='utf-8')"
```

If shell encoding is unreliable, build `content` with Unicode escape sequences.

## 2. PowerShell .NET UTF-8 no-BOM write

```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path $path), $content, $utf8NoBom)
```

## 3. Verify actual content, not terminal appearance

### Show escaped code points

```powershell
python -c "from pathlib import Path; text = Path('README.md').read_text(encoding='utf-8'); print(text[:500].encode('unicode_escape').decode())"
```

### Check for literal replacement damage

```powershell
python -c "from pathlib import Path; text = Path('README.md').read_text(encoding='utf-8'); print('????' in text)"
```

### Check BOM or first bytes

```powershell
python -c "from pathlib import Path; print(Path('README.md').read_bytes()[:3].hex())"
```

## 4. Known pitfalls

- `Set-Content` may follow host or session encoding behavior you did not intend.
- Raw Chinese text inside PowerShell here-strings can still be damaged before it reaches the file.
- Terminal mojibake does not prove the file is broken.
- Literal `?` characters usually mean lossy rewriting already happened.

## 5. Patch vs Rewrite

Choose full rewrite over patch when:
- the file contains Chinese text and large sections are changing
- the file is already garbled or contains literal `?`
- file moves or renames just happened and stale copies may exist
- repeated patch attempts are making the file less trustworthy

Safe fallback:

```powershell
python -c "from pathlib import Path; Path('README.md').write_text(final_text, encoding='utf-8')"
```

Then verify with:

```powershell
python -c "from pathlib import Path; text = Path('README.md').read_text(encoding='utf-8'); print(text[:500].encode('unicode_escape').decode())"
```

## 6. Recovery

If a file is already full of `?`, do not keep patching it from terminal output. Rebuild from a trusted source and rewrite via Python UTF-8.

---
name: encoding-safe-writes
description: Use this skill when editing repository files that may contain CJK text or when PowerShell/terminal encoding could corrupt file contents. It documents safe UTF-8 write patterns, verification steps, recovery tactics, and when to prefer full-file rewrites over patching.
---

# Encoding Safe Writes

Use this skill whenever you need to edit files in this repo and there is any realistic chance that PowerShell, terminal output, or file-write APIs could damage UTF-8 text.

This is especially important for:
- Markdown files with Chinese text
- docs, README, specs, and skill files
- any workflow that uses PowerShell here-strings, `Set-Content`, or terminal copy/paste

## Core Rule

Do not trust terminal rendering alone.

A file can be:
- actually broken on disk
- perfectly fine on disk but displayed as mojibake in the terminal
- rewritten into literal `?` characters by a lossy write path

These are different failure modes and must be distinguished before fixing anything.

## Safe Workflow

1. Read the file as UTF-8 from a reliable reader.
   - Prefer Python or explicit UTF-8 reads.
2. Check raw bytes before editing.
   - Confirm whether the file has BOM.
   - Confirm whether the content already contains literal `?` replacement damage.
3. Write using a UTF-8 safe path.
   - Prefer Python `Path.write_text(..., encoding="utf-8")`.
   - In PowerShell, prefer `.NET` file APIs with `UTF8Encoding($false)`.
4. Verify after write.
   - Re-read as UTF-8.
   - Inspect leading bytes.
   - When terminal rendering is unreliable, print `unicode_escape` output from Python to verify actual code points.

## What Went Wrong In This Repo

These concrete issues happened during refactoring and should be treated as known hazards:

- Writing Chinese Markdown through PowerShell heredoc or direct shell content caused files to become literal `?` characters.
- Some files were valid UTF-8 on disk, but terminal display still looked garbled. This was a display problem, not a file-content problem.
- Some edits accidentally introduced UTF-8 BOM.
- Some string content was copied through unsafe shell paths and lost CJK characters permanently, requiring full rewrite from a trusted source.
- Patch-style edits after file moves landed on stale duplicate files and created confusing divergence.
- Repeated patch retries after corruption made files less trustworthy instead of safer.

## Write Methods

### Preferred: Python UTF-8 write

Use Python to write exact text when CJK safety matters.

```powershell
python -c "from pathlib import Path; Path('README.md').write_text(content, encoding='utf-8')"
```

When shell encoding is suspicious, build `content` using Unicode escapes instead of raw Chinese in the shell command.

### Acceptable: .NET UTF-8 no-BOM write

If you must stay in PowerShell, use `.NET` explicitly.

```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

### Avoid

Avoid these for CJK-sensitive files unless you have verified the exact host behavior:
- `Set-Content`
- `Out-File`
- shell heredoc with raw Chinese content
- copying terminal-rendered mojibake back into the file

## Patch Safety

Encoding issues and patch issues often happen together.

### When `apply_patch` is a bad fit

Do not force a patch when one of these is true:
- the file already contains mojibake or literal `?` damage
- the file contains a lot of CJK text and you need to rewrite large sections
- the patch tool or sandbox is failing repeatedly
- the edit is effectively a full-file rewrite

In these cases, a clean UTF-8 rewrite is safer than a line patch.

### Practical rule

- Small ASCII-only code edits: `apply_patch` is usually fine.
- Small localized text edits in trusted UTF-8 files: patch is acceptable if verification follows.
- Large Markdown/doc rewrites, especially with Chinese text: prefer full rewrite via Python UTF-8 write.

### After file moves or renames

When files are moved, always verify all of the following before patching further:
- there is only one live copy of the file
- scene / preload / import paths point to the new location
- editor or cache metadata is not still pointing at the old path

If duplicate old copies remain, delete or retire them first. Otherwise later patches may land on the wrong file and create confusing divergence.

## Verification Checklist

### Check whether the file is truly broken

Use Python to inspect text content without relying on terminal rendering:

```powershell
python -c "from pathlib import Path; text = Path('README.md').read_text(encoding='utf-8'); print(text[:500].encode('unicode_escape').decode())"
```

If the output shows `\u4e2d\u6587`-style escapes, the file still contains real Chinese text.

### Check whether the file was rewritten into `?`

```powershell
python -c "from pathlib import Path; text = Path('README.md').read_text(encoding='utf-8'); print('????' in text)"
```

If the file already contains literal `?`, the content was damaged and must be restored from a trusted source.

### Check BOM

```powershell
python -c "from pathlib import Path; print(Path('README.md').read_bytes()[:3].hex())"
```

Common values:
- `efbbbf` = UTF-8 with BOM
- anything else = inspect further

## Recovery Tactics

If a Chinese file becomes garbled:

1. Stop editing through normal shell text paths.
2. Determine whether the problem is display-only or file-content corruption.
3. If content is still valid, do not rewrite the whole file unnecessarily.
4. If the file contains literal `?`, reconstruct from a trusted source and rewrite via Python UTF-8.
5. Reopen the file in the IDE after write; editor tabs may cache old broken content.

## Practical Rule Of Thumb

- For ASCII-only code edits: ordinary edits are usually fine.
- For Chinese docs or mixed-language Markdown: use Python UTF-8 writes by default.
- If terminal output looks suspicious: verify with `unicode_escape`, not by eyesight.

## Reference

See `references/powershell-utf8.md` for the concrete PowerShell patterns.

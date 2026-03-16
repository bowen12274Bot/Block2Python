#!/usr/bin/env python3
"""
Skill 封裝工具：將 skill 資料夾打包成可分發的 `.skill` 檔案。

Usage:
    python utils/package_skill.py <path/to/skill-folder> [output-directory]

Example:
    python utils/package_skill.py skills/public/my-skill
    python utils/package_skill.py skills/public/my-skill ./dist
"""

import sys
import zipfile
from pathlib import Path

from quick_validate import validate_skill


def _is_within(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def package_skill(skill_path, output_dir=None):
    """將 skill 資料夾封裝成 `.skill` 檔案。"""
    skill_path = Path(skill_path).resolve()

    if not skill_path.exists():
        print(f"[錯誤] 找不到 skill 資料夾：{skill_path}")
        return None

    if not skill_path.is_dir():
        print(f"[錯誤] 指定路徑不是資料夾：{skill_path}")
        return None

    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        print(f"[錯誤] 在 {skill_path} 中找不到 SKILL.md")
        return None

    print("正在驗證 skill...")
    valid, message = validate_skill(skill_path)
    if not valid:
        print(f"[錯誤] 驗證失敗：{message}")
        print("   請先修正驗證錯誤，再重新封裝。")
        return None
    print(f"[完成] {message}\n")

    skill_name = skill_path.name
    if output_dir:
        output_path = Path(output_dir).resolve()
        output_path.mkdir(parents=True, exist_ok=True)
    else:
        output_path = Path.cwd()

    skill_filename = output_path / f"{skill_name}.skill"

    excluded_dirs = {".git", ".svn", ".hg", "__pycache__", "node_modules"}

    try:
        with zipfile.ZipFile(skill_filename, "w", zipfile.ZIP_DEFLATED) as zipf:
            for file_path in skill_path.rglob("*"):
                if file_path.is_symlink():
                    print(f"[警告] 略過 symlink：{file_path}")
                    continue

                rel_parts = file_path.relative_to(skill_path).parts
                if any(part in excluded_dirs for part in rel_parts):
                    continue

                if file_path.is_file():
                    resolved_file = file_path.resolve()
                    if not _is_within(resolved_file, skill_path):
                        print(f"[錯誤] 檔案超出 skill 根目錄：{file_path}")
                        return None
                    if resolved_file == skill_filename.resolve():
                        print(f"[警告] 略過輸出封裝檔：{file_path}")
                        continue

                    arcname = Path(skill_name) / file_path.relative_to(skill_path)
                    zipf.write(file_path, arcname)
                    print(f"  已加入：{arcname}")

        print(f"\n[完成] Skill 已封裝完成：{skill_filename}")
        return skill_filename

    except Exception as e:
        print(f"[錯誤] 建立 .skill 檔失敗：{e}")
        return None


def main():
    if len(sys.argv) < 2:
        print("Usage: python utils/package_skill.py <path/to/skill-folder> [output-directory]")
        print("\nExample:")
        print("  python utils/package_skill.py skills/public/my-skill")
        print("  python utils/package_skill.py skills/public/my-skill ./dist")
        sys.exit(1)

    skill_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None

    print(f"正在封裝 skill：{skill_path}")
    if output_dir:
        print(f"   輸出目錄：{output_dir}")
    print()

    result = package_skill(skill_path, output_dir)

    if result:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Skill 快速驗證腳本。"""

import re
import sys
from pathlib import Path
from typing import Optional

try:
    import yaml
except ModuleNotFoundError:
    yaml = None

MAX_SKILL_NAME_LENGTH = 64


def _extract_frontmatter(content: str) -> Optional[str]:
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return "\n".join(lines[1:i])
    return None


def _parse_simple_frontmatter(frontmatter_text: str) -> Optional[dict[str, str]]:
    """
    PyYAML 不可用時的最小 frontmatter 解析器。
    僅支援 `key: value` 這種簡單結構。
    """
    parsed: dict[str, str] = {}
    current_key: Optional[str] = None
    for raw_line in frontmatter_text.splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        is_indented = raw_line[:1].isspace()
        if is_indented:
            if current_key is None:
                return None
            current_value = parsed[current_key]
            parsed[current_key] = (
                f"{current_value}\n{stripped}" if current_value else stripped
            )
            continue

        if ":" not in stripped:
            return None
        key, value = stripped.split(":", 1)
        key = key.strip()
        value = value.strip()
        if not key:
            return None
        if (value.startswith('"') and value.endswith('"')) or (
            value.startswith("'") and value.endswith("'")
        ):
            value = value[1:-1]
        parsed[key] = value
        current_key = key
    return parsed


def validate_skill(skill_path):
    """執行 skill 的基礎驗證。"""
    skill_path = Path(skill_path)

    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        return False, "找不到 SKILL.md"

    try:
        content = skill_md.read_text(encoding="utf-8")
    except OSError as e:
        return False, f"無法讀取 SKILL.md：{e}"

    frontmatter_text = _extract_frontmatter(content)
    if frontmatter_text is None:
        return False, "Frontmatter 格式無效"
    if yaml is not None:
        try:
            frontmatter = yaml.safe_load(frontmatter_text)
            if not isinstance(frontmatter, dict):
                return False, "Frontmatter 必須是 YAML dictionary"
        except yaml.YAMLError as e:
            return False, f"Frontmatter 內的 YAML 無效：{e}"
    else:
        frontmatter = _parse_simple_frontmatter(frontmatter_text)
        if frontmatter is None:
            return (
                False,
                "Frontmatter 內的 YAML 無效：未安裝 PyYAML 時不支援此語法",
            )

    allowed_properties = {"name", "description", "license", "allowed-tools", "metadata"}

    unexpected_keys = set(frontmatter.keys()) - allowed_properties
    if unexpected_keys:
        allowed = ", ".join(sorted(allowed_properties))
        unexpected = ", ".join(sorted(unexpected_keys))
        return (
            False,
            f"SKILL.md frontmatter 含有未預期欄位：{unexpected}。允許欄位為：{allowed}",
        )

    if "name" not in frontmatter:
        return False, "Frontmatter 缺少 'name'"
    if "description" not in frontmatter:
        return False, "Frontmatter 缺少 'description'"

    name = frontmatter.get("name", "")
    if not isinstance(name, str):
        return False, f"name 必須是字串，實際為 {type(name).__name__}"
    name = name.strip()
    if name:
        if not re.match(r"^[a-z0-9-]+$", name):
            return (
                False,
                f"name '{name}' 必須是 hyphen-case（只允許小寫英文字母、數字與連字號）",
            )
        if name.startswith("-") or name.endswith("-") or "--" in name:
            return (
                False,
                f"name '{name}' 不能以連字號開頭或結尾，也不能包含連續連字號",
            )
        if len(name) > MAX_SKILL_NAME_LENGTH:
            return (
                False,
                f"name 過長（{len(name)} 字元）。上限是 {MAX_SKILL_NAME_LENGTH} 字元。",
            )

    description = frontmatter.get("description", "")
    if not isinstance(description, str):
        return False, f"description 必須是字串，實際為 {type(description).__name__}"
    description = description.strip()
    if description:
        if "<" in description or ">" in description:
            return False, "description 不能包含角括號（< 或 >）"
        if len(description) > 1024:
            return (
                False,
                f"description 過長（{len(description)} 字元）。上限是 1024 字元。",
            )

    return True, "Skill 驗證通過"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)

    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)

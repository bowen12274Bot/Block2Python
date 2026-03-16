#!/usr/bin/env python3
"""
Block2Python skill 初始化工具。

本工具只會在 `.agent/skills/` 下建立 canonical skill。
`.agents/`、`.claude/`、`.codex/` 是不同 AI 模型的入口，不是 skill source，
因此本工具不會在那些目錄下建立或同步 skill 檔案。
"""

import argparse
import re
import sys
from pathlib import Path

MAX_SKILL_NAME_LENGTH = 64
ALLOWED_RESOURCES = {"scripts", "references", "assets"}
PROJECT_ROOT = Path(__file__).resolve().parents[4]
PROJECT_SKILLS_DIR = PROJECT_ROOT / ".agent" / "skills"

DEFAULT_DESCRIPTION = (
    "[TODO: 清楚說明這個 skill 做什麼，以及何時該使用它。"
    "請把觸發情境、任務類型或檔案類型寫進來。]"
)

SKILL_TEMPLATE = """---
name: {skill_name}
description: {description}
---

# {skill_title}

使用此 skill 處理 [TODO: 補上此 skill 的主要任務]。

## 範圍

- [TODO: 列出這個 skill 負責的任務範圍]
- [TODO: 補上第二點，避免只有一句空泛描述]

## 先讀

- 專案架構：[`docs/project_architecture.md`](../../../docs/project_architecture.md)
- 協作入口：[`docs/contributing.md`](../../../docs/contributing.md)
- AI 協作規範：[`docs/contributing/ai_collaboration.md`](../../../docs/contributing/ai_collaboration.md)

## 操作指引

- [TODO: 寫出主要工作規則]
- [TODO: 如果有固定流程，在這裡列出]
- [TODO: 如果需要按需讀取 references，請明確指出何時讀哪一份]

## 資源

只建立真正需要的資源目錄；不需要就刪除整節。

### scripts/

放可直接執行的工具腳本，適合重複性高或需要穩定輸出的工作。

### references/

放按需載入的參考文件，例如 API 文件、schema、長流程說明或專案慣例。

### assets/

放最終輸出會直接使用，但不需要先載入上下文的檔案，例如模板、圖片或字型。

## 驗證

- [TODO: 補上這個 skill 對應的驗證方式]
- [TODO: 若沒有自動化驗證，至少寫出最小人工檢查方式]
"""

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""
{skill_name} 的範例輔助腳本。
"""


def main():
    print("這是 {skill_name} 的範例腳本")


if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = """# {skill_title} 參考文件

這是一份參考文件占位內容。

## 何時讀取

- 需要更完整的背景知識時
- 主 `SKILL.md` 無法容納所有細節時
- 只有特定情境才會需要這份資料時
"""

EXAMPLE_ASSET = """# 範例資源檔

這是資源檔占位內容。
請依需求替換成真正的模板、圖片、字型等檔案，或在不需要時刪除。
"""


def normalize_skill_name(skill_name):
    """將 skill 名稱正規化為小寫 hyphen-case。"""
    normalized = skill_name.strip().lower()
    normalized = re.sub(r"[^a-z0-9]+", "-", normalized)
    normalized = normalized.strip("-")
    normalized = re.sub(r"-{2,}", "-", normalized)
    return normalized


def title_case_skill_name(skill_name):
    """將 hyphen-case 名稱轉成顯示用標題。"""
    return " ".join(word.capitalize() for word in skill_name.split("-"))


def parse_resources(raw_resources):
    if not raw_resources:
        return []
    resources = [item.strip() for item in raw_resources.split(",") if item.strip()]
    invalid = sorted({item for item in resources if item not in ALLOWED_RESOURCES})
    if invalid:
        allowed = ", ".join(sorted(ALLOWED_RESOURCES))
        print(f"[錯誤] 未知的資源類型：{', '.join(invalid)}")
        print(f"   允許值：{allowed}")
        sys.exit(1)
    deduped = []
    seen = set()
    for resource in resources:
        if resource not in seen:
            deduped.append(resource)
            seen.add(resource)
    return deduped


def create_resource_dirs(skill_dir, skill_name, skill_title, resources, include_examples):
    for resource in resources:
        resource_dir = skill_dir / resource
        resource_dir.mkdir(exist_ok=True)
        if resource == "scripts":
            if include_examples:
                example_script = resource_dir / "example.py"
                example_script.write_text(
                    EXAMPLE_SCRIPT.format(skill_name=skill_name),
                    encoding="utf-8",
                )
                example_script.chmod(0o755)
                print("[完成] 已建立 scripts/example.py")
            else:
                print("[完成] 已建立 scripts/")
        elif resource == "references":
            if include_examples:
                example_reference = resource_dir / "api_reference.md"
                example_reference.write_text(
                    EXAMPLE_REFERENCE.format(skill_title=skill_title),
                    encoding="utf-8",
                )
                print("[完成] 已建立 references/api_reference.md")
            else:
                print("[完成] 已建立 references/")
        elif resource == "assets":
            if include_examples:
                example_asset = resource_dir / "example_asset.txt"
                example_asset.write_text(EXAMPLE_ASSET, encoding="utf-8")
                print("[完成] 已建立 assets/example_asset.txt")
            else:
                print("[完成] 已建立 assets/")


def init_skill(skill_name, path=None, resources=None, include_examples=False):
    """依 Block2Python 專案格式初始化新的 canonical skill。"""
    resources = resources or []
    target_root = PROJECT_SKILLS_DIR if path is None else Path(path).resolve()
    skill_dir = target_root / skill_name

    if skill_dir.exists():
        print(f"[錯誤] Skill 目錄已存在：{skill_dir}")
        return None

    try:
        skill_dir.mkdir(parents=True, exist_ok=False)
        print(f"[完成] 已建立 skill 目錄：{skill_dir}")
    except Exception as e:
        print(f"[錯誤] 建立目錄失敗：{e}")
        return None

    skill_title = title_case_skill_name(skill_name)
    skill_content = SKILL_TEMPLATE.format(
        skill_name=skill_name,
        skill_title=skill_title,
        description=DEFAULT_DESCRIPTION,
    )

    skill_md_path = skill_dir / "SKILL.md"
    try:
        skill_md_path.write_text(skill_content, encoding="utf-8")
        print("[完成] 已建立 SKILL.md")
    except Exception as e:
        print(f"[錯誤] 建立 SKILL.md 失敗：{e}")
        return None

    if resources:
        try:
            create_resource_dirs(skill_dir, skill_name, skill_title, resources, include_examples)
        except Exception as e:
            print(f"[錯誤] 建立資源目錄失敗：{e}")
            return None

    print(f"\n[完成] Skill '{skill_name}' 已初始化：{skill_dir}")
    print("\n接下來建議：")
    print("1. 編輯 canonical SKILL.md，完成 TODO 並補上 description")
    if target_root == PROJECT_SKILLS_DIR:
        print("2. 更新 `.agent/SKILLS.md`，補上新 skill 的索引與用途摘要")
        print("3. 如有需要，再由各模型入口自行指向 `.agent/skills/` 這份 canonical skill")
    else:
        print("2. 確認這個自訂路徑是否符合你的使用情境")
    if resources:
        if include_examples:
            print("4. 調整或刪除 scripts/、references/、assets/ 內的範例檔")
        else:
            print("4. 依需求補上 scripts/、references/、assets/ 內容")
    else:
        print("4. 只有在需要時才建立 scripts/、references/、assets/")
    print("5. 準備好後執行 validator 檢查 skill 結構")

    return skill_dir


def main():
    parser = argparse.ArgumentParser(
        description="依 Block2Python 專案格式建立新的 canonical skill。",
    )
    parser.add_argument("skill_name", help="Skill 名稱（會正規化為 hyphen-case）")
    parser.add_argument(
        "--path",
        help="Skill 的輸出目錄；未提供時預設為 `.agent/skills/`",
    )
    parser.add_argument(
        "--resources",
        default="",
        help="以逗號分隔的資源類型：scripts,references,assets",
    )
    parser.add_argument(
        "--examples",
        action="store_true",
        help="在選定的資源目錄中建立範例檔案",
    )
    args = parser.parse_args()

    raw_skill_name = args.skill_name
    skill_name = normalize_skill_name(raw_skill_name)
    if not skill_name:
        print("[錯誤] Skill 名稱至少要包含一個英文字母或數字。")
        sys.exit(1)
    if len(skill_name) > MAX_SKILL_NAME_LENGTH:
        print(
            f"[錯誤] Skill 名稱 '{skill_name}' 過長（{len(skill_name)} 字元）。"
            f"上限是 {MAX_SKILL_NAME_LENGTH} 字元。"
        )
        sys.exit(1)
    if skill_name != raw_skill_name:
        print(f"注意：已將 skill 名稱從 '{raw_skill_name}' 正規化為 '{skill_name}'。")

    resources = parse_resources(args.resources)
    if args.examples and not resources:
        print("[錯誤] 使用 --examples 時必須同時提供 --resources。")
        sys.exit(1)

    path = Path(args.path).resolve() if args.path else PROJECT_SKILLS_DIR

    print(f"正在初始化 skill：{skill_name}")
    print(f"   位置：{path}")
    if resources:
        print(f"   資源：{', '.join(resources)}")
        if args.examples:
            print("   範例檔：啟用")
    else:
        print("   資源：無（需要時再建立）")
    print()

    result = init_skill(
        skill_name,
        path=path,
        resources=resources,
        include_examples=args.examples,
    )

    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()

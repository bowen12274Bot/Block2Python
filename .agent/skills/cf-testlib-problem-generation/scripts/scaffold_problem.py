#!/usr/bin/env python3
"""Scaffold a Codeforces-style problem workspace from local templates."""

from __future__ import annotations

import argparse
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
TEMPLATE_DIR = SKILL_ROOT / "assets" / "templates"


def write_file(path: Path, content: str, force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"Refusing to overwrite existing file: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def load_template(name: str) -> str:
    template_path = TEMPLATE_DIR / name
    return template_path.read_text(encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Create a CF/testlib problem scaffold.",
    )
    parser.add_argument("problem_name", help="Folder name of the new problem")
    parser.add_argument(
        "--output",
        default=".",
        help="Output root directory (default: current directory)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing files if present",
    )
    args = parser.parse_args()

    problem_root = Path(args.output).resolve() / args.problem_name
    (problem_root / "solutions").mkdir(parents=True, exist_ok=True)
    (problem_root / "testlib").mkdir(parents=True, exist_ok=True)
    (problem_root / "tests" / "samples").mkdir(parents=True, exist_ok=True)
    (problem_root / "tests" / "pretests").mkdir(parents=True, exist_ok=True)
    (problem_root / "tests" / "system").mkdir(parents=True, exist_ok=True)

    statement = """# Problem Title

## Statement

[TODO]

## Input

[TODO]

## Output

[TODO]

## Constraints

- [TODO]

## Notes

- [TODO]
"""

    write_file(problem_root / "statement.md", statement, args.force)

    write_file(
        problem_root / "solutions" / "solution.cpp",
        load_template("solution.cpp"),
        args.force,
    )
    write_file(
        problem_root / "solutions" / "brute.cpp",
        load_template("brute.cpp"),
        args.force,
    )
    write_file(
        problem_root / "testlib" / "generator.cpp",
        load_template("generator.cpp"),
        args.force,
    )
    write_file(
        problem_root / "testlib" / "validator.cpp",
        load_template("validator.cpp"),
        args.force,
    )
    write_file(
        problem_root / "testlib" / "checker.cpp",
        load_template("checker.cpp"),
        args.force,
    )

    print(f"Scaffold created at: {problem_root}")
    print("Next: fill statement.md and adjust templates to your actual problem.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

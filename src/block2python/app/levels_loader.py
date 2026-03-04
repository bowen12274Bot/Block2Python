from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from block2python.contracts import LevelSpec, Testcase


class LevelsLoadError(Exception):
    pass


def load_levels(levels_dir: Path) -> dict[str, LevelSpec]:
    index_path = levels_dir / "index.json"
    if not index_path.exists():
        raise LevelsLoadError(f"Missing levels index: {index_path}")

    try:
        index = json.loads(index_path.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        raise LevelsLoadError(f"Failed to read index.json: {e}") from e

    items = index.get("levels")
    if not isinstance(items, list):
        raise LevelsLoadError("index.json must contain a list field: levels")

    levels: dict[str, LevelSpec] = {}
    for item in items:
        if not isinstance(item, dict):
            continue
        level_id = str(item.get("id", "")).strip()
        file_rel = str(item.get("file", "")).strip()
        if not level_id or not file_rel:
            continue

        level_path = levels_dir / file_rel
        levels[level_id] = _load_level_file(level_path)

    if not levels:
        raise LevelsLoadError("No levels loaded from index.json")
    return levels


def _load_level_file(level_path: Path) -> LevelSpec:
    try:
        raw = json.loads(level_path.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        raise LevelsLoadError(f"Failed to read level file {level_path}: {e}") from e

    if not isinstance(raw, dict):
        raise LevelsLoadError(f"Level file must be an object: {level_path}")

    level_id = str(raw.get("level_id", "")).strip()
    title = str(raw.get("title", "")).strip()
    if not level_id or not title:
        raise LevelsLoadError(f"level_id/title required: {level_path}")

    testcases_raw = raw.get("testcases", [])
    testcases: list[Testcase] = []
    if isinstance(testcases_raw, list):
        for tc in testcases_raw:
            if not isinstance(tc, dict):
                continue
            stdin = str(tc.get("stdin", ""))
            expected_stdout = str(tc.get("expected_stdout", ""))
            name = tc.get("name")
            testcases.append(Testcase(stdin=stdin, expected_stdout=expected_stdout, name=str(name) if name else None))

    prerequisite_level_ids = tuple(str(x) for x in raw.get("prerequisite_level_ids", ()) if isinstance(x, (str, int)))
    next_level_ids = tuple(str(x) for x in raw.get("next_level_ids", ()) if isinstance(x, (str, int)))

    metadata: dict[str, Any] = {}
    md_raw = raw.get("metadata", {})
    if isinstance(md_raw, dict):
        metadata.update(md_raw)

    return LevelSpec(
        level_id=level_id,
        title=title,
        chapter_id=_opt_str(raw.get("chapter_id")),
        quest_id=_opt_str(raw.get("quest_id")),
        order_index=_opt_int(raw.get("order_index")),
        prompt=str(raw.get("prompt", "")),
        learning_markdown=str(raw.get("learning_markdown", "")),
        story_intro_markdown=str(raw.get("story_intro_markdown", "")),
        story_outro_markdown=str(raw.get("story_outro_markdown", "")),
        prerequisite_level_ids=prerequisite_level_ids,
        next_level_ids=next_level_ids,
        testcases=tuple(testcases),
        block_schema_version=_opt_str(raw.get("block_schema_version")),
        metadata=metadata,
    )


def _opt_str(v: object) -> str | None:
    if v is None:
        return None
    s = str(v).strip()
    return s if s else None


def _opt_int(v: object) -> int | None:
    if v is None:
        return None
    if isinstance(v, int):
        return v
    try:
        return int(str(v))
    except ValueError:
        return None


from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from block2python.contracts import AnalysisPolicy, JudgePolicy, LevelSpec, OutputNormalization, Testcase


class LevelsLoadError(Exception):
    pass


def load_levels(levels_dir: Path) -> dict[str, LevelSpec]:
    index_path = _resolve_index_path(levels_dir)

    try:
        index = _read_structured_file(index_path)
    except Exception as e:  # noqa: BLE001
        raise LevelsLoadError(f"Failed to read index file {index_path.name}: {e}") from e

    items = index.get("levels")
    if not isinstance(items, list):
        raise LevelsLoadError(f"{index_path.name} must contain a list field: levels")

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
        raise LevelsLoadError(f"No levels loaded from {index_path.name}")
    return levels


def _load_level_file(level_path: Path) -> LevelSpec:
    try:
        raw = _read_structured_file(level_path)
    except Exception as e:  # noqa: BLE001
        raise LevelsLoadError(f"Failed to read level file {level_path}: {e}") from e

    if not isinstance(raw, dict):
        raise LevelsLoadError(f"Level file must be an object: {level_path}")

    level_id = str(raw.get("level_id", "")).strip()
    title = str(raw.get("title", "")).strip()
    if not level_id or not title:
        raise LevelsLoadError(f"level_id/title required: {level_path}")

    testcases = _load_testcases(raw, level_path)

    prerequisite_level_ids = tuple(str(x) for x in raw.get("prerequisite_level_ids", ()) if isinstance(x, (str, int)))
    next_level_ids = tuple(str(x) for x in raw.get("next_level_ids", ()) if isinstance(x, (str, int)))

    metadata: dict[str, Any] = {}
    md_raw = raw.get("metadata", {})
    if isinstance(md_raw, dict):
        metadata.update(md_raw)

    analysis_policy = _analysis_policy_from_metadata(metadata)
    judge_policy = _judge_policy_from_raw(raw.get("judge_policy"))

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
        judge_policy=judge_policy,
        analysis_policy=analysis_policy,
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


def _analysis_policy_from_metadata(metadata: dict[str, Any]) -> AnalysisPolicy:
    """
    Establishment-phase hook:
      - Allow per-level analysis rules to be configured via level.metadata
      - If absent/malformed, fall back to empty AnalysisPolicy (no extra rules)

    Supported (optional) shapes:
      - metadata["analysis"]["required_keywords"] = ["for", "input"]
      - metadata["analysis"]["forbidden_keywords"] = ["import", "while"]
    """

    analysis = metadata.get("analysis")
    if not isinstance(analysis, dict):
        return AnalysisPolicy()

    required_raw = analysis.get("required_keywords", ())
    forbidden_raw = analysis.get("forbidden_keywords", ())

    required: list[str] = []
    if isinstance(required_raw, list):
        required = [str(x) for x in required_raw if str(x)]

    forbidden: list[str] = []
    if isinstance(forbidden_raw, list):
        forbidden = [str(x) for x in forbidden_raw if str(x)]

    return AnalysisPolicy(required_keywords=tuple(required), forbidden_keywords=tuple(forbidden))


def _judge_policy_from_raw(raw: object) -> JudgePolicy:
    if not isinstance(raw, dict):
        return JudgePolicy()

    tl_raw = raw.get("time_limit_ms", JudgePolicy().time_limit_ms)
    time_limit_ms = JudgePolicy().time_limit_ms
    memory_limit_kb = _opt_positive_int(raw.get("memory_limit_kb"))
    if memory_limit_kb is None:
        memory_limit_mb = _opt_positive_int(raw.get("memory_limit_mb"))
        if memory_limit_mb is not None:
            memory_limit_kb = memory_limit_mb * 1024

    if isinstance(tl_raw, int):
        time_limit_ms = max(1, tl_raw)
    else:
        try:
            time_limit_ms = max(1, int(str(tl_raw)))
        except ValueError:
            time_limit_ms = JudgePolicy().time_limit_ms

    norm_raw = raw.get("output_normalization", {})
    if not isinstance(norm_raw, dict):
        return JudgePolicy(time_limit_ms=time_limit_ms, memory_limit_kb=memory_limit_kb)

    normalization = OutputNormalization(
        strip_trailing_whitespace=bool(norm_raw.get("strip_trailing_whitespace", True)),
        normalize_newlines_to_lf=bool(norm_raw.get("normalize_newlines_to_lf", True)),
        strip_trailing_newline=bool(norm_raw.get("strip_trailing_newline", True)),
    )
    return JudgePolicy(
        time_limit_ms=time_limit_ms,
        memory_limit_kb=memory_limit_kb,
        output_normalization=normalization,
    )


def _resolve_index_path(levels_dir: Path) -> Path:
    for name in ("index.json", "index.yaml", "index.yml"):
        candidate = levels_dir / name
        if candidate.exists():
            return candidate
    raise LevelsLoadError(f"Missing levels index in {levels_dir} (expected index.json/index.yaml/index.yml)")


def _read_structured_file(path: Path) -> Any:
    suffix = path.suffix.lower()
    text = path.read_text(encoding="utf-8")
    if suffix == ".json":
        return json.loads(text)
    if suffix in {".yaml", ".yml"}:
        try:
            import yaml
        except ImportError as e:  # pragma: no cover
            raise LevelsLoadError("PyYAML is required to load .yaml level files") from e
        return yaml.safe_load(text)
    raise LevelsLoadError(f"Unsupported structured file type: {path}")


def _load_testcases(raw: dict[str, Any], level_path: Path) -> list[Testcase]:
    testcases: list[Testcase] = []
    testcases_raw = raw.get("testcases", [])
    if isinstance(testcases_raw, list):
        for tc in testcases_raw:
            if not isinstance(tc, dict):
                continue
            loaded = _testcase_from_raw(tc, level_path)
            if loaded is not None:
                testcases.append(loaded)

    if testcases:
        return testcases

    return _discover_testcases_from_dir(raw, level_path)


def _testcase_from_raw(tc: dict[str, Any], level_path: Path) -> Testcase | None:
    name = tc.get("name")
    if "stdin" in tc or "expected_stdout" in tc:
        return Testcase(
            stdin=str(tc.get("stdin", "")),
            expected_stdout=str(tc.get("expected_stdout", "")),
            name=str(name) if name else None,
        )

    base_file = _opt_str(tc.get("base_file"))
    if base_file:
        stdin_path = _resolve_relative_path(level_path, f"{base_file}.in")
        stdout_path = _resolve_relative_path(level_path, f"{base_file}.out")
        return _testcase_from_paths(stdin_path, stdout_path, name=str(name) if name else Path(base_file).name)

    stdin_file = _opt_str(tc.get("stdin_file") or tc.get("in"))
    stdout_file = _opt_str(tc.get("expected_stdout_file") or tc.get("out"))
    if stdin_file and stdout_file:
        stdin_path = _resolve_relative_path(level_path, stdin_file)
        stdout_path = _resolve_relative_path(level_path, stdout_file)
        return _testcase_from_paths(stdin_path, stdout_path, name=str(name) if name else Path(stdin_file).stem)

    return None


def _discover_testcases_from_dir(raw: dict[str, Any], level_path: Path) -> list[Testcase]:
    testcase_dir_raw = _opt_str(raw.get("testcase_dir") or raw.get("cases_dir"))
    if not testcase_dir_raw:
        return []

    testcase_dir = _resolve_relative_path(level_path, testcase_dir_raw)
    if not testcase_dir.exists() or not testcase_dir.is_dir():
        raise LevelsLoadError(f"Testcase directory not found: {testcase_dir}")

    pattern = _opt_str(raw.get("testcase_glob")) or "*.in"
    testcases: list[Testcase] = []
    for stdin_path in sorted(testcase_dir.glob(pattern)):
        if stdin_path.suffix.lower() != ".in":
            continue
        stdout_path = stdin_path.with_suffix(".out")
        testcases.append(_testcase_from_paths(stdin_path, stdout_path, name=stdin_path.stem))
    return testcases


def _testcase_from_paths(stdin_path: Path, stdout_path: Path, *, name: str | None) -> Testcase:
    if not stdin_path.exists():
        raise LevelsLoadError(f"Missing testcase input file: {stdin_path}")
    if not stdout_path.exists():
        raise LevelsLoadError(f"Missing testcase output file: {stdout_path}")
    return Testcase(
        stdin=stdin_path.read_text(encoding="utf-8"),
        expected_stdout=stdout_path.read_text(encoding="utf-8"),
        name=name,
    )


def _resolve_relative_path(level_path: Path, relative_path: str) -> Path:
    return (level_path.parent / relative_path).resolve()


def _opt_positive_int(v: object) -> int | None:
    parsed = _opt_int(v)
    if parsed is None:
        return None
    return parsed if parsed > 0 else None

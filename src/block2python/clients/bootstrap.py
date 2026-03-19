from __future__ import annotations

import os
from pathlib import Path

from block2python.level_play import AppCore, JsonFileProgress, build_judge_from_env
from block2python.content import LevelsLoadError, load_levels
from block2python.contracts import LevelSpec


def default_progress_path() -> Path:
    return Path(".block2python") / "progress.json"


def configured_levels_dir() -> Path:
    configured = os.environ.get("BLOCK2PYTHON_LEVELS_DIR")
    if configured:
        return Path(configured)
    return Path("assets") / "levels"


def load_configured_levels() -> dict[str, LevelSpec]:
    levels_dir = configured_levels_dir()
    try:
        return load_levels(levels_dir)
    except LevelsLoadError as exc:
        raise RuntimeError(f"Failed to load levels from {levels_dir}: {exc}") from exc


def build_configured_app() -> tuple[AppCore, dict[str, LevelSpec], str]:
    levels = load_configured_levels()
    judge, judge_info = build_judge_from_env()
    app = AppCore(levels, judge=judge, progress=JsonFileProgress(default_progress_path()))
    return app, levels, judge_info


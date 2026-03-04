from __future__ import annotations

import os
from pathlib import Path

from block2python.contracts import LevelSpec

from .levels_loader import LevelsLoadError, load_levels


def demo_levels() -> dict[str, LevelSpec]:
    """
    Current behavior:
      - Load level data from `assets/levels/*.json` (via index.json)
      - This keeps level content editable without touching Python code.
    """

    levels_dir = _levels_dir()
    try:
        return load_levels(levels_dir)
    except LevelsLoadError as e:
        raise RuntimeError(f"Failed to load demo levels from {levels_dir}: {e}") from e


def _levels_dir() -> Path:
    configured = os.environ.get("BLOCK2PYTHON_LEVELS_DIR")
    if configured:
        return Path(configured)
    return Path("assets") / "levels"

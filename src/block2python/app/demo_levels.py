from __future__ import annotations

from block2python.contracts import LevelSpec

from .runtime import load_configured_levels


def demo_levels() -> dict[str, LevelSpec]:
    """Backward-compatible wrapper around the configured level catalog."""

    return load_configured_levels()

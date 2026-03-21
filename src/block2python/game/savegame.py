from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class SaveGame:
    """Skeleton-phase placeholder for future savegame work."""

    save_version: str = "0.1"
    player_name: str = ""
    player_gender: str = ""
    profile_created: bool = False
    current_node_id: str | None = None
    completed_node_ids: tuple[str, ...] = ()
    cleared_level_ids: tuple[str, ...] = ()
    story_flags: dict[str, bool] = field(default_factory=dict)

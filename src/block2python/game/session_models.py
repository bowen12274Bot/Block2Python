from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class SessionMode(str, Enum):
    SCENE = "SCENE"
    DEMO = "DEMO"
    CHALLENGE = "CHALLENGE"
    COMPLETE = "COMPLETE"


class GameSessionError(Exception):
    """Raised when the game session receives an invalid action."""


@dataclass(frozen=True, slots=True)
class GameSessionState:
    mode: SessionMode
    quest_id: str
    node_id: str | None = None
    node_title: str = ""
    scene_id: str | None = None
    demo_id: str | None = None
    challenge_id: str | None = None
    current_level_id: str | None = None
    current_level_title: str | None = None
    current_level_prompt: str | None = None


@dataclass(slots=True)
class GroupRuntimeState:
    group_id: str
    unlock_state: str = "locked"
    display_state: str = "locked"
    entered_once: bool = False
    demo_seen: bool = False
    practice_unlocked: bool = False
    practice_completed_count: int = 0
    practice_total_count: int = 0
    practice_current_level_id: str | None = None
    practice_last_level_id: str | None = None
    practice_reviewing: bool = False
    completed: bool = False


@dataclass(slots=True)
class PracticeBatteryState:
    group_id: str
    battery_percent: int = 0
    awarded_level_ids: set[str] = field(default_factory=set)

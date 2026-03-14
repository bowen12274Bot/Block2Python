from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class GameMode(str, Enum):
    SCENE = "scene"
    CHALLENGE = "challenge"
    COMPLETE = "complete"


class ActionType(str, Enum):
    ADVANCE = "advance"
    SUBMIT_LEVEL = "submit_level"
    RESTART_QUEST = "restart_quest"


@dataclass(frozen=True, slots=True)
class DialogueBlockState:
    speaker: str
    text: str
    portrait_id: str | None = None
    expression: str | None = None
    emphasis: str | None = None


@dataclass(frozen=True, slots=True)
class SceneState:
    scene_id: str
    title: str
    dialogue_blocks: tuple[DialogueBlockState, ...] = ()


@dataclass(frozen=True, slots=True)
class ChallengeState:
    challenge_id: str
    challenge_type: str
    current_level_id: str | None = None
    current_level_title: str | None = None


@dataclass(frozen=True, slots=True)
class ProgressState:
    completed_node_ids: tuple[str, ...] = ()
    cleared_level_ids: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class AvailableActions:
    advance: bool = False
    submit: bool = False
    restart_quest: bool = False


@dataclass(frozen=True, slots=True)
class SubmissionFeedback:
    level_id: str
    cleared: bool
    block_passed: bool
    analysis_status: str
    analysis_summary: str = ""
    judge_status: str = ""
    judge_summary: str = ""


@dataclass(frozen=True, slots=True)
class GameState:
    mode: GameMode
    quest_id: str
    node_id: str | None = None
    node_title: str = ""
    scene: SceneState | None = None
    challenge: ChallengeState | None = None
    progress: ProgressState = field(default_factory=ProgressState)
    available_actions: AvailableActions = field(default_factory=AvailableActions)
    last_submission: SubmissionFeedback | None = None
    errors: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class PlayerAction:
    action_type: ActionType
    payload: dict[str, Any] = field(default_factory=dict)

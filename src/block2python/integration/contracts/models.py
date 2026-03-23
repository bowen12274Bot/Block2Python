from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class GameMode(str, Enum):
    SCENE = "scene"
    DEMO = "demo"
    CHALLENGE = "challenge"
    COMPLETE = "complete"


class ActionType(str, Enum):
    ADVANCE = "advance"
    SUBMIT_LEVEL = "submit_level"
    VERIFY_TOOLBOX_LEVEL = "verify_toolbox_level"
    START_GROUP_STORY = "start_group_story"
    START_GROUP_DEMO = "start_group_demo"
    START_GROUP_PRACTICE = "start_group_practice"
    CREATE_PLAYER_PROFILE = "create_player_profile"
    COMPLETE_INTRO = "complete_intro"
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
class DemoState:
    demo_id: str
    title: str
    body: str = ""
    current_level_id: str | None = None


@dataclass(frozen=True, slots=True)
class ChallengeState:
    challenge_id: str
    challenge_type: str
    current_level_id: str | None = None
    current_level_title: str | None = None
    current_level_prompt: str | None = None


@dataclass(frozen=True, slots=True)
class PlayerProfileState:
    name: str = ""
    gender: str = ""
    profile_created: bool = False


@dataclass(frozen=True, slots=True)
class ProgressState:
    completed_node_ids: tuple[str, ...] = ()
    cleared_level_ids: tuple[str, ...] = ()
    demo_seen_group_ids: tuple[str, ...] = ()
    toolbox_used_level_ids: tuple[str, ...] = ()


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
    verification_only: bool = False
    answer_correct: bool = False


@dataclass(frozen=True, slots=True)
class GroupSlotState:
    slot_key: str
    title: str
    status_key: str
    status_label: str
    is_unlocked: bool = False
    viewed: bool = False
    completed_count: int = 0
    total_count: int = 0
    next_level_id: str | None = None
    entry_level_id: str | None = None


@dataclass(frozen=True, slots=True)
class MapRouteStepState:
    step_id: str
    step_type: str
    title: str
    target_page: str
    status_key: str
    status_label: str
    tracked_node_ids: tuple[str, ...] = ()
    level_ids: tuple[str, ...] = ()
    node_id: str | None = None
    scene_id: str | None = None
    challenge_id: str | None = None
    is_planned: bool = False
    is_repeatable: bool = False


@dataclass(frozen=True, slots=True)
class GroupMapRouteState:
    group_id: str
    title: str
    status_key: str = "locked"
    status_label: str = "Locked"
    is_enterable: bool = False
    current_label: str = ""
    demo_slot: GroupSlotState | None = None
    practice_slot: GroupSlotState | None = None
    demo_route: tuple[MapRouteStepState, ...] = ()
    practice_route: tuple[MapRouteStepState, ...] = ()


@dataclass(frozen=True, slots=True)
class MapRouteState:
    route_id: str
    quest_id: str
    title: str
    groups: tuple[GroupMapRouteState, ...] = ()


@dataclass(frozen=True, slots=True)
class GameState:
    mode: GameMode
    quest_id: str
    node_id: str | None = None
    node_title: str = ""
    player_profile: PlayerProfileState = field(default_factory=PlayerProfileState)
    intro_completed: bool = False
    scene: SceneState | None = None
    demo: DemoState | None = None
    challenge: ChallengeState | None = None
    progress: ProgressState = field(default_factory=ProgressState)
    available_actions: AvailableActions = field(default_factory=AvailableActions)
    last_submission: SubmissionFeedback | None = None
    map_route: MapRouteState | None = None
    errors: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class PlayerAction:
    action_type: ActionType
    payload: dict[str, Any] = field(default_factory=dict)

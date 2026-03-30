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
    RUN_LEVEL = "run_level"
    NEXT_LEVEL = "next_level"
    SUBMIT_LEVEL = "submit_level"
    VERIFY_TOOLBOX_LEVEL = "verify_toolbox_level"
    CONFIRM_TOOLBOX_OPEN = "confirm_toolbox_open"
    START_GROUP_STORY = "start_group_story"
    START_GROUP_DEMO = "start_group_demo"
    START_GROUP_PRACTICE = "start_group_practice"
    CREATE_PLAYER_PROFILE = "create_player_profile"
    COMPLETE_INTRO = "complete_intro"
    RESTART_QUEST = "restart_quest"


@dataclass(frozen=True, slots=True)
class ActorCueState:
    actor_id: str | None = None
    display_name: str | None = None
    portrait_id: str | None = None
    expression_id: str | None = None
    pose_id: str | None = None
    visual_state: str | None = None
    image_path: str | None = None


@dataclass(frozen=True, slots=True)
class DialogueBlockState:
    speaker: str
    text: str
    portrait_id: str | None = None
    expression: str | None = None
    background_id: str | None = None
    emphasis: str | None = None
    speaker_side: str | None = None
    left_actor: ActorCueState | None = None
    center_actor: ActorCueState | None = None
    right_actor: ActorCueState | None = None


@dataclass(frozen=True, slots=True)
class SceneState:
    scene_id: str
    title: str
    dialogue_blocks: tuple[DialogueBlockState, ...] = ()
    mission_statement_scene_id: str | None = None
    mission_statement_title: str = ""
    mission_statement_text: str = ""


@dataclass(frozen=True, slots=True)
class DemoState:
    demo_id: str
    title: str
    group_id: str | None = None
    level_id: str | None = None
    prompt: str = ""
    learning_markdown: str = ""
    story_intro_markdown: str = ""
    story_outro_markdown: str = ""
    can_advance: bool = False
    body: str = ""
    current_level_id: str | None = None
    unlock_blocks: tuple[dict[str, str], ...] = ()
    toolbox_block_ids: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class PracticeState:
    challenge_id: str
    challenge_type: str
    group_id: str | None = None
    level_id: str | None = None
    level_title: str | None = None
    prompt: str = ""
    progress_current: int = 0
    progress_total: int = 0
    is_review_mode: bool = False
    toolbox_allowed: bool = False
    toolbox_used: bool = False
    toolbox_opened: bool = False
    toolbox_penalty_percent: int | None = None
    toolbox_block_ids: tuple[str, ...] = ()
    can_run: bool = False
    can_submit: bool = False
    can_next: bool = False
    mission_text: str = ""
    battery_percent: int = 0
    battery_threshold_percent: int = 80
    assistant_messages: tuple[str, ...] = ()
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
    run: bool = False
    submit: bool = False
    next_level: bool = False
    restart_quest: bool = False


@dataclass(frozen=True, slots=True)
class SubmissionFeedback:
    level_id: str
    cleared: bool
    block_passed: bool
    analysis_status: str
    kind: str = "submission"
    status_label: str = ""
    analysis_summary: str = ""
    judge_status: str = ""
    judge_summary: str = ""
    verification_only: bool = False
    answer_correct: bool = False
    output_text: str = ""
    details: dict[str, Any] = field(default_factory=dict)


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
    practice: PracticeState | None = None
    progress: ProgressState = field(default_factory=ProgressState)
    available_actions: AvailableActions = field(default_factory=AvailableActions)
    last_submission: SubmissionFeedback | None = None
    map_route: MapRouteState | None = None
    errors: tuple[str, ...] = ()

    @property
    def challenge_id(self) -> str | None:
        if self.practice is None:
            return None
        return self.practice.challenge_id

    @property
    def current_level_id(self) -> str | None:
        if self.demo is not None and self.demo.current_level_id is not None:
            return self.demo.current_level_id
        if self.practice is not None:
            return self.practice.current_level_id
        return None

    @property
    def current_level_title(self) -> str | None:
        if self.practice is not None:
            return self.practice.current_level_title
        return None

    @property
    def current_level_prompt(self) -> str | None:
        if self.practice is not None:
            return self.practice.current_level_prompt
        return None


@dataclass(frozen=True, slots=True)
class PlayerAction:
    action_type: ActionType
    payload: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class TutorReplyRequest:
    question: str
    provider: str = "template"
    level_id: str | None = None
    python_code: str = ""
    block_json: dict[str, Any] | None = None
    conversation_id: str | None = None
    conversation_history: tuple[dict[str, Any], ...] = ()
    history_summary: str | None = None
    recent_feedback: tuple[str, ...] = ()
    provider_options: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class TutorReplyPayload:
    reply_type: str
    content: str
    metadata: dict[str, Any] = field(default_factory=dict)

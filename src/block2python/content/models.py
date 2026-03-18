from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from block2python.contracts import LevelSpec


@dataclass(frozen=True, slots=True)
class DialogueBlock:
    speaker: str
    text: str
    portrait_id: str | None = None
    expression: str | None = None
    emphasis: str | None = None


@dataclass(frozen=True, slots=True)
class SceneSpec:
    scene_id: str
    title: str
    dialogue_blocks: tuple[DialogueBlock, ...] = ()
    next_action: str = ""
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class NodeSpec:
    node_id: str
    node_type: str
    title: str
    prerequisite_node_ids: tuple[str, ...] = ()
    next_node_ids: tuple[str, ...] = ()
    scene_id: str | None = None
    challenge_group_id: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class QuestSpec:
    quest_id: str
    title: str
    node_ids: tuple[str, ...] = ()
    entry_node_id: str | None = None
    completion_node_id: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class ChallengeSpec:
    challenge_id: str
    challenge_type: str
    title: str
    level_ids: tuple[str, ...] = ()
    toolbox_policy_id: str | None = None
    battery_policy_id: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class MapRouteStepSpec:
    step_id: str
    step_type: str
    title: str
    target_page: str
    tracked_node_ids: tuple[str, ...] = ()
    node_id: str | None = None
    scene_id: str | None = None
    challenge_id: str | None = None
    level_ids: tuple[str, ...] = ()
    is_planned: bool = False
    is_repeatable: bool = False
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class GroupMapRoutesSpec:
    group_id: str
    title: str
    demo_route: tuple[MapRouteStepSpec, ...] = ()
    practice_route: tuple[MapRouteStepSpec, ...] = ()
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class MapRouteSpec:
    route_id: str
    quest_id: str
    title: str
    groups: tuple[GroupMapRoutesSpec, ...] = ()
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class ToolboxPolicySpec:
    toolbox_id: str
    unlocked_block_ids: tuple[str, ...] = ()
    allow_toolbox_in_practice: bool = False
    toolbox_reward_percent: int | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class BatteryPolicySpec:
    battery_policy_id: str
    full_reward_percent: int | None = None
    toolbox_reward_percent: int | None = None
    pass_threshold_percent: int | None = None
    accepted_pass_values: tuple[int, ...] = ()
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class GameContentBundle:
    quests: dict[str, QuestSpec] = field(default_factory=dict)
    nodes: dict[str, NodeSpec] = field(default_factory=dict)
    scenes: dict[str, SceneSpec] = field(default_factory=dict)
    challenges: dict[str, ChallengeSpec] = field(default_factory=dict)
    map_routes: dict[str, MapRouteSpec] = field(default_factory=dict)
    toolbox: dict[str, ToolboxPolicySpec] = field(default_factory=dict)
    battery_policies: dict[str, BatteryPolicySpec] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class ResolvedChallengeSpec:
    challenge_id: str
    challenge_type: str
    title: str
    levels: tuple[LevelSpec, ...] = ()
    toolbox_policy: ToolboxPolicySpec | None = None
    battery_policy: BatteryPolicySpec | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class AssembledGameSlice:
    quests: dict[str, QuestSpec]
    nodes: dict[str, NodeSpec]
    scenes: dict[str, SceneSpec]
    challenges: dict[str, ResolvedChallengeSpec]
    map_routes: dict[str, MapRouteSpec]
    levels: dict[str, LevelSpec]

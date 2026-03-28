from __future__ import annotations

from pathlib import Path
from typing import Any

from .errors import GameContentLoadError
from .models import (
    ActorCue,
    BatteryPolicySpec,
    ChallengeSpec,
    DialogueBlock,
    GroupMapRoutesSpec,
    MapRouteSpec,
    MapRouteStepSpec,
    NodeSpec,
    QuestSpec,
    SceneSpec,
    ToolboxPolicySpec,
)
from .raw_utils import (
    expect_dict,
    metadata_from_raw,
    optional_int,
    optional_str,
    require_int_list,
    require_list,
    require_str,
    require_str_list,
)


def parse_node_file(path: Path, raw: Any) -> tuple[NodeSpec, ...]:
    data = expect_dict(path, raw)
    nodes_raw = data.get("nodes")
    if not isinstance(nodes_raw, list) or not nodes_raw:
        raise GameContentLoadError(f"{path.name} must contain a non-empty nodes list")

    parsed = [node_from_raw(path, item) for item in nodes_raw]
    ids = {node.node_id for node in parsed}
    if len(ids) != len(parsed):
        raise GameContentLoadError(f"Duplicate node_id in {path.name}")
    return tuple(parsed)


def parse_map_route_file(path: Path, raw: Any) -> tuple[MapRouteSpec, ...]:
    data = expect_dict(path, raw)
    map_routes_raw = data.get("map_routes")
    if not isinstance(map_routes_raw, list) or not map_routes_raw:
        raise GameContentLoadError(f"{path.name} must contain a non-empty map_routes list")

    parsed = [map_route_from_raw(path, item) for item in map_routes_raw]
    ids = {route.route_id for route in parsed}
    if len(ids) != len(parsed):
        raise GameContentLoadError(f"Duplicate route_id in {path.name}")
    return tuple(parsed)


def parse_scene_file(path: Path, raw: Any) -> tuple[str, SceneSpec]:
    data = expect_dict(path, raw)
    scene = SceneSpec(
        scene_id=require_str(data, "scene_id", context=path.name),
        title=require_str(data, "title", context=path.name),
        dialogue_blocks=tuple(
            dialogue_block_from_raw(path, item) for item in require_list(data, "dialogue_blocks", path)
        ),
        next_action=require_str(data, "next_action", context=path.name),
        metadata=metadata_from_raw(data),
    )
    return scene.scene_id, scene


def parse_quest_file(path: Path, raw: Any) -> tuple[str, QuestSpec]:
    data = expect_dict(path, raw)
    quest = QuestSpec(
        quest_id=require_str(data, "quest_id", context=path.name),
        title=require_str(data, "title", context=path.name),
        node_ids=tuple(require_str_list(data.get("node_ids"), field_name="node_ids", context=path.name)),
        entry_node_id=optional_str(data.get("entry_node_id")),
        completion_node_id=optional_str(data.get("completion_node_id")),
        metadata=metadata_from_raw(data),
    )
    return quest.quest_id, quest


def parse_challenge_file(path: Path, raw: Any) -> tuple[str, ChallengeSpec]:
    data = expect_dict(path, raw)
    challenge = ChallengeSpec(
        challenge_id=require_str(data, "challenge_id", context=path.name),
        challenge_type=require_str(data, "challenge_type", context=path.name),
        title=require_str(data, "title", context=path.name),
        level_ids=tuple(require_str_list(data.get("level_ids"), field_name="level_ids", context=path.name)),
        toolbox_policy_id=optional_str(data.get("toolbox_policy_id")),
        battery_policy_id=optional_str(data.get("battery_policy_id")),
        metadata=metadata_from_raw(data),
    )
    return challenge.challenge_id, challenge


def parse_toolbox_file(path: Path, raw: Any) -> tuple[str, ToolboxPolicySpec]:
    data = expect_dict(path, raw)
    toolbox = ToolboxPolicySpec(
        toolbox_id=require_str(data, "toolbox_id", context=path.name),
        unlocked_block_ids=tuple(
            require_str_list(data.get("unlocked_block_ids"), field_name="unlocked_block_ids", context=path.name)
        ),
        allow_toolbox_in_practice=bool(data.get("allow_toolbox_in_practice", False)),
        toolbox_reward_percent=optional_int(data.get("toolbox_reward_percent")),
        metadata=metadata_from_raw(data),
    )
    return toolbox.toolbox_id, toolbox


def parse_battery_file(path: Path, raw: Any) -> tuple[str, BatteryPolicySpec]:
    data = expect_dict(path, raw)
    battery = BatteryPolicySpec(
        battery_policy_id=require_str(data, "battery_policy_id", context=path.name),
        full_reward_percent=optional_int(data.get("full_reward_percent")),
        toolbox_reward_percent=optional_int(data.get("toolbox_reward_percent")),
        pass_threshold_percent=optional_int(data.get("pass_threshold_percent")),
        accepted_pass_values=tuple(
            require_int_list(data.get("accepted_pass_values"), field_name="accepted_pass_values", context=path.name)
        ),
        metadata=metadata_from_raw(data),
    )
    return battery.battery_policy_id, battery


def dialogue_block_from_raw(path: Path, raw: Any) -> DialogueBlock:
    data = expect_dict(path, raw)
    return DialogueBlock(
        speaker=require_str(data, "speaker", context=path.name),
        text=require_str(data, "text", context=path.name),
        portrait_id=optional_str(data.get("portrait_id")),
        expression=optional_str(data.get("expression")),
        background_id=optional_str(data.get("background_id")),
        emphasis=optional_str(data.get("emphasis")),
        speaker_side=optional_str(data.get("speaker_side")),
        left_actor=actor_cue_from_raw(data.get("left_actor")),
        center_actor=actor_cue_from_raw(data.get("center_actor")),
        right_actor=actor_cue_from_raw(data.get("right_actor")),
    )


def actor_cue_from_raw(raw: Any) -> ActorCue | None:
    if raw is None:
        return None
    if not isinstance(raw, dict):
        raise GameContentLoadError(f"Dialogue actor cue must be an object, got: {raw!r}")
    return ActorCue(
        actor_id=optional_str(raw.get("actor_id")),
        display_name=optional_str(raw.get("display_name")),
        portrait_id=optional_str(raw.get("portrait_id")),
        expression_id=optional_str(raw.get("expression_id")),
        pose_id=optional_str(raw.get("pose_id")),
        visual_state=optional_str(raw.get("visual_state")),
        image_path=optional_str(raw.get("image_path")),
    )


def node_from_raw(path: Path, raw: Any) -> NodeSpec:
    data = expect_dict(path, raw)
    return NodeSpec(
        node_id=require_str(data, "node_id", context=path.name),
        node_type=require_str(data, "node_type", context=path.name),
        title=require_str(data, "title", context=path.name),
        prerequisite_node_ids=tuple(
            require_str_list(data.get("prerequisite_node_ids", []), field_name="prerequisite_node_ids", context=path.name)
        ),
        next_node_ids=tuple(require_str_list(data.get("next_node_ids", []), field_name="next_node_ids", context=path.name)),
        scene_id=optional_str(data.get("scene_id")),
        mission_statement_scene_id=optional_str(data.get("mission_statement_scene_id")),
        challenge_group_id=optional_str(data.get("challenge_group_id")),
        metadata=metadata_from_raw(data),
    )


def map_route_from_raw(path: Path, raw: Any) -> MapRouteSpec:
    data = expect_dict(path, raw)
    groups_raw = require_list(data, "groups", path)
    groups = tuple(group_map_routes_from_raw(path, item) for item in groups_raw)
    return MapRouteSpec(
        route_id=require_str(data, "route_id", context=path.name),
        quest_id=require_str(data, "quest_id", context=path.name),
        title=require_str(data, "title", context=path.name),
        groups=groups,
        metadata=metadata_from_raw(data),
    )


def group_map_routes_from_raw(path: Path, raw: Any) -> GroupMapRoutesSpec:
    data = expect_dict(path, raw)
    demo_route_raw = require_list(data, "demo_route", path)
    practice_route_raw = require_list(data, "practice_route", path)
    return GroupMapRoutesSpec(
        group_id=require_str(data, "group_id", context=path.name),
        title=require_str(data, "title", context=path.name),
        demo_route=tuple(map_route_step_from_raw(path, item) for item in demo_route_raw),
        practice_route=tuple(map_route_step_from_raw(path, item) for item in practice_route_raw),
        metadata=metadata_from_raw(data),
    )


def map_route_step_from_raw(path: Path, raw: Any) -> MapRouteStepSpec:
    data = expect_dict(path, raw)
    return MapRouteStepSpec(
        step_id=require_str(data, "step_id", context=path.name),
        step_type=require_str(data, "step_type", context=path.name),
        title=require_str(data, "title", context=path.name),
        target_page=require_str(data, "target_page", context=path.name),
        tracked_node_ids=tuple(
            require_str_list(data.get("tracked_node_ids", []), field_name="tracked_node_ids", context=path.name)
        ),
        node_id=optional_str(data.get("node_id")),
        scene_id=optional_str(data.get("scene_id")),
        challenge_id=optional_str(data.get("challenge_id")),
        level_ids=tuple(require_str_list(data.get("level_ids", []), field_name="level_ids", context=path.name)),
        is_planned=bool(data.get("is_planned", False)),
        is_repeatable=bool(data.get("is_repeatable", False)),
        metadata=metadata_from_raw(data),
    )
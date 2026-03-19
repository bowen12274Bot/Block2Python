from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable, TypeVar

from block2python.contracts import LevelSpec

from .errors import GameContentAssemblyError, GameContentLoadError
from .models import (
    AssembledGameSlice,
    BatteryPolicySpec,
    ChallengeSpec,
    DialogueBlock,
    GameContentBundle,
    GroupMapRoutesSpec,
    MapRouteSpec,
    MapRouteStepSpec,
    NodeSpec,
    QuestSpec,
    ResolvedChallengeSpec,
    SceneSpec,
    ToolboxPolicySpec,
)

T = TypeVar("T")


def load_game_content(game_content_dir: Path) -> GameContentBundle:
    index_path = _resolve_index_path(game_content_dir)
    raw_index = _read_structured_file(index_path)
    if not isinstance(raw_index, dict):
        raise GameContentLoadError(f"Index file must be an object: {index_path}")

    return GameContentBundle(
        quests=_load_group(raw_index, game_content_dir, "quests", _parse_quest_file),
        nodes=_load_nodes_group(raw_index, game_content_dir),
        scenes=_load_group(raw_index, game_content_dir, "scenes", _parse_scene_file),
        challenges=_load_group(raw_index, game_content_dir, "challenges", _parse_challenge_file),
        map_routes=_load_map_routes_group(raw_index, game_content_dir),
        toolbox=_load_group(raw_index, game_content_dir, "toolbox", _parse_toolbox_file),
        battery_policies=_load_group(raw_index, game_content_dir, "battery", _parse_battery_file),
    )


def assemble_game_slice(*, game_content: GameContentBundle, levels: dict[str, LevelSpec]) -> AssembledGameSlice:
    _validate_nodes(game_content.nodes, game_content.scenes, game_content.challenges)
    _validate_quests(game_content.quests, game_content.nodes)
    _validate_map_routes(
        game_content.map_routes,
        game_content.quests,
        game_content.nodes,
        game_content.scenes,
        game_content.challenges,
        levels,
    )

    resolved_challenges: dict[str, ResolvedChallengeSpec] = {}
    for challenge_id, challenge in game_content.challenges.items():
        resolved_levels: list[LevelSpec] = []
        for level_id in challenge.level_ids:
            level = levels.get(level_id)
            if level is None:
                raise GameContentAssemblyError(
                    f"Challenge {challenge_id} references missing level_id: {level_id}"
                )
            resolved_levels.append(level)

        toolbox_policy = None
        if challenge.toolbox_policy_id is not None:
            toolbox_policy = game_content.toolbox.get(challenge.toolbox_policy_id)
            if toolbox_policy is None:
                raise GameContentAssemblyError(
                    f"Challenge {challenge_id} references missing toolbox_policy_id: {challenge.toolbox_policy_id}"
                )

        battery_policy = None
        if challenge.battery_policy_id is not None:
            battery_policy = game_content.battery_policies.get(challenge.battery_policy_id)
            if battery_policy is None:
                raise GameContentAssemblyError(
                    f"Challenge {challenge_id} references missing battery_policy_id: {challenge.battery_policy_id}"
                )

        resolved_challenges[challenge_id] = ResolvedChallengeSpec(
            challenge_id=challenge.challenge_id,
            challenge_type=challenge.challenge_type,
            title=challenge.title,
            levels=tuple(resolved_levels),
            toolbox_policy=toolbox_policy,
            battery_policy=battery_policy,
            metadata=dict(challenge.metadata),
        )

    return AssembledGameSlice(
        quests=dict(game_content.quests),
        nodes=dict(game_content.nodes),
        scenes=dict(game_content.scenes),
        challenges=resolved_challenges,
        map_routes=dict(game_content.map_routes),
        levels=dict(levels),
    )


def _load_group(
    raw_index: dict[str, Any],
    base_dir: Path,
    key: str,
    parser: Callable[[Path, Any], tuple[str, T]],
) -> dict[str, T]:
    items = raw_index.get(key, [])
    if not isinstance(items, list):
        raise GameContentLoadError(f"{base_dir.name}/index must contain list field: {key}")

    loaded: dict[str, T] = {}
    for item in items:
        if not isinstance(item, dict):
            raise GameContentLoadError(f"{key} entries must be objects")
        file_rel = _require_str(item, "file", context=key)
        path = (base_dir / file_rel).resolve()
        obj_id, obj = parser(path, _read_structured_file(path))
        if obj_id in loaded:
            raise GameContentLoadError(f"Duplicate {key} id: {obj_id}")
        loaded[obj_id] = obj
    return loaded


def _load_nodes_group(raw_index: dict[str, Any], base_dir: Path) -> dict[str, NodeSpec]:
    items = raw_index.get("nodes", [])
    if not isinstance(items, list):
        raise GameContentLoadError(f"{base_dir.name}/index must contain list field: nodes")

    loaded: dict[str, NodeSpec] = {}
    for item in items:
        if not isinstance(item, dict):
            raise GameContentLoadError("nodes entries must be objects")
        file_rel = _require_str(item, "file", context="nodes")
        path = (base_dir / file_rel).resolve()
        for node in _parse_node_file(path, _read_structured_file(path)):
            if node.node_id in loaded:
                raise GameContentLoadError(f"Duplicate nodes id: {node.node_id}")
            loaded[node.node_id] = node
    return loaded


def _load_map_routes_group(raw_index: dict[str, Any], base_dir: Path) -> dict[str, MapRouteSpec]:
    items = raw_index.get("map_routes", [])
    if not isinstance(items, list):
        raise GameContentLoadError(f"{base_dir.name}/index must contain list field: map_routes")

    loaded: dict[str, MapRouteSpec] = {}
    for item in items:
        if not isinstance(item, dict):
            raise GameContentLoadError("map_routes entries must be objects")
        file_rel = _require_str(item, "file", context="map_routes")
        path = (base_dir / file_rel).resolve()
        for route in _parse_map_route_file(path, _read_structured_file(path)):
            if route.route_id in loaded:
                raise GameContentLoadError(f"Duplicate map_routes id: {route.route_id}")
            loaded[route.route_id] = route
    return loaded


def _parse_node_file(path: Path, raw: Any) -> tuple[NodeSpec, ...]:
    data = _expect_dict(path, raw)
    nodes_raw = data.get("nodes")
    if not isinstance(nodes_raw, list) or not nodes_raw:
        raise GameContentLoadError(f"{path.name} must contain a non-empty nodes list")

    parsed = [_node_from_raw(path, item) for item in nodes_raw]
    ids = {node.node_id for node in parsed}
    if len(ids) != len(parsed):
        raise GameContentLoadError(f"Duplicate node_id in {path.name}")
    return tuple(parsed)


def _parse_map_route_file(path: Path, raw: Any) -> tuple[MapRouteSpec, ...]:
    data = _expect_dict(path, raw)
    map_routes_raw = data.get("map_routes")
    if not isinstance(map_routes_raw, list) or not map_routes_raw:
        raise GameContentLoadError(f"{path.name} must contain a non-empty map_routes list")

    parsed = [_map_route_from_raw(path, item) for item in map_routes_raw]
    ids = {route.route_id for route in parsed}
    if len(ids) != len(parsed):
        raise GameContentLoadError(f"Duplicate route_id in {path.name}")
    return tuple(parsed)


def _parse_scene_file(path: Path, raw: Any) -> tuple[str, SceneSpec]:
    data = _expect_dict(path, raw)
    scene = SceneSpec(
        scene_id=_require_str(data, "scene_id", context=path.name),
        title=_require_str(data, "title", context=path.name),
        dialogue_blocks=tuple(
            _dialogue_block_from_raw(path, item) for item in _require_list(data, "dialogue_blocks", path)
        ),
        next_action=_require_str(data, "next_action", context=path.name),
        metadata=_metadata_from_raw(data),
    )
    return scene.scene_id, scene


def _parse_quest_file(path: Path, raw: Any) -> tuple[str, QuestSpec]:
    data = _expect_dict(path, raw)
    quest = QuestSpec(
        quest_id=_require_str(data, "quest_id", context=path.name),
        title=_require_str(data, "title", context=path.name),
        node_ids=tuple(_require_str_list(data.get("node_ids"), field_name="node_ids", context=path.name)),
        entry_node_id=_optional_str(data.get("entry_node_id")),
        completion_node_id=_optional_str(data.get("completion_node_id")),
        metadata=_metadata_from_raw(data),
    )
    return quest.quest_id, quest


def _parse_challenge_file(path: Path, raw: Any) -> tuple[str, ChallengeSpec]:
    data = _expect_dict(path, raw)
    challenge = ChallengeSpec(
        challenge_id=_require_str(data, "challenge_id", context=path.name),
        challenge_type=_require_str(data, "challenge_type", context=path.name),
        title=_require_str(data, "title", context=path.name),
        level_ids=tuple(_require_str_list(data.get("level_ids"), field_name="level_ids", context=path.name)),
        toolbox_policy_id=_optional_str(data.get("toolbox_policy_id")),
        battery_policy_id=_optional_str(data.get("battery_policy_id")),
        metadata=_metadata_from_raw(data),
    )
    return challenge.challenge_id, challenge


def _parse_toolbox_file(path: Path, raw: Any) -> tuple[str, ToolboxPolicySpec]:
    data = _expect_dict(path, raw)
    toolbox = ToolboxPolicySpec(
        toolbox_id=_require_str(data, "toolbox_id", context=path.name),
        unlocked_block_ids=tuple(
            _require_str_list(data.get("unlocked_block_ids"), field_name="unlocked_block_ids", context=path.name)
        ),
        allow_toolbox_in_practice=bool(data.get("allow_toolbox_in_practice", False)),
        toolbox_reward_percent=_optional_int(data.get("toolbox_reward_percent")),
        metadata=_metadata_from_raw(data),
    )
    return toolbox.toolbox_id, toolbox


def _parse_battery_file(path: Path, raw: Any) -> tuple[str, BatteryPolicySpec]:
    data = _expect_dict(path, raw)
    battery = BatteryPolicySpec(
        battery_policy_id=_require_str(data, "battery_policy_id", context=path.name),
        full_reward_percent=_optional_int(data.get("full_reward_percent")),
        toolbox_reward_percent=_optional_int(data.get("toolbox_reward_percent")),
        pass_threshold_percent=_optional_int(data.get("pass_threshold_percent")),
        accepted_pass_values=tuple(
            _require_int_list(data.get("accepted_pass_values"), field_name="accepted_pass_values", context=path.name)
        ),
        metadata=_metadata_from_raw(data),
    )
    return battery.battery_policy_id, battery


def _dialogue_block_from_raw(path: Path, raw: Any) -> DialogueBlock:
    data = _expect_dict(path, raw)
    return DialogueBlock(
        speaker=_require_str(data, "speaker", context=path.name),
        text=_require_str(data, "text", context=path.name),
        portrait_id=_optional_str(data.get("portrait_id")),
        expression=_optional_str(data.get("expression")),
        emphasis=_optional_str(data.get("emphasis")),
    )


def _node_from_raw(path: Path, raw: Any) -> NodeSpec:
    data = _expect_dict(path, raw)
    return NodeSpec(
        node_id=_require_str(data, "node_id", context=path.name),
        node_type=_require_str(data, "node_type", context=path.name),
        title=_require_str(data, "title", context=path.name),
        prerequisite_node_ids=tuple(
            _require_str_list(data.get("prerequisite_node_ids", []), field_name="prerequisite_node_ids", context=path.name)
        ),
        next_node_ids=tuple(_require_str_list(data.get("next_node_ids", []), field_name="next_node_ids", context=path.name)),
        scene_id=_optional_str(data.get("scene_id")),
        challenge_group_id=_optional_str(data.get("challenge_group_id")),
        metadata=_metadata_from_raw(data),
    )


def _map_route_from_raw(path: Path, raw: Any) -> MapRouteSpec:
    data = _expect_dict(path, raw)
    groups_raw = _require_list(data, "groups", path)
    groups = tuple(_group_map_routes_from_raw(path, item) for item in groups_raw)
    return MapRouteSpec(
        route_id=_require_str(data, "route_id", context=path.name),
        quest_id=_require_str(data, "quest_id", context=path.name),
        title=_require_str(data, "title", context=path.name),
        groups=groups,
        metadata=_metadata_from_raw(data),
    )


def _group_map_routes_from_raw(path: Path, raw: Any) -> GroupMapRoutesSpec:
    data = _expect_dict(path, raw)
    demo_route_raw = _require_list(data, "demo_route", path)
    practice_route_raw = _require_list(data, "practice_route", path)
    return GroupMapRoutesSpec(
        group_id=_require_str(data, "group_id", context=path.name),
        title=_require_str(data, "title", context=path.name),
        demo_route=tuple(_map_route_step_from_raw(path, item) for item in demo_route_raw),
        practice_route=tuple(_map_route_step_from_raw(path, item) for item in practice_route_raw),
        metadata=_metadata_from_raw(data),
    )


def _map_route_step_from_raw(path: Path, raw: Any) -> MapRouteStepSpec:
    data = _expect_dict(path, raw)
    return MapRouteStepSpec(
        step_id=_require_str(data, "step_id", context=path.name),
        step_type=_require_str(data, "step_type", context=path.name),
        title=_require_str(data, "title", context=path.name),
        target_page=_require_str(data, "target_page", context=path.name),
        tracked_node_ids=tuple(
            _require_str_list(data.get("tracked_node_ids", []), field_name="tracked_node_ids", context=path.name)
        ),
        node_id=_optional_str(data.get("node_id")),
        scene_id=_optional_str(data.get("scene_id")),
        challenge_id=_optional_str(data.get("challenge_id")),
        level_ids=tuple(_require_str_list(data.get("level_ids", []), field_name="level_ids", context=path.name)),
        is_planned=bool(data.get("is_planned", False)),
        is_repeatable=bool(data.get("is_repeatable", False)),
        metadata=_metadata_from_raw(data),
    )


def _validate_nodes(
    nodes: dict[str, NodeSpec],
    scenes: dict[str, SceneSpec],
    challenges: dict[str, ChallengeSpec],
) -> None:
    for node_id, node in nodes.items():
        for ref in node.prerequisite_node_ids:
            if ref not in nodes:
                raise GameContentAssemblyError(f"Node {node_id} references missing prerequisite_node_id: {ref}")
        for ref in node.next_node_ids:
            if ref not in nodes:
                raise GameContentAssemblyError(f"Node {node_id} references missing next_node_id: {ref}")
        if node.scene_id is not None and node.scene_id not in scenes:
            raise GameContentAssemblyError(f"Node {node_id} references missing scene_id: {node.scene_id}")
        if node.challenge_group_id is not None and node.challenge_group_id not in challenges:
            raise GameContentAssemblyError(
                f"Node {node_id} references missing challenge_group_id: {node.challenge_group_id}"
            )


def _validate_quests(quests: dict[str, QuestSpec], nodes: dict[str, NodeSpec]) -> None:
    for quest_id, quest in quests.items():
        for node_id in quest.node_ids:
            if node_id not in nodes:
                raise GameContentAssemblyError(f"Quest {quest_id} references missing node_id: {node_id}")
        if quest.entry_node_id is not None and quest.entry_node_id not in nodes:
            raise GameContentAssemblyError(f"Quest {quest_id} references missing entry_node_id: {quest.entry_node_id}")
        if quest.completion_node_id is not None and quest.completion_node_id not in nodes:
            raise GameContentAssemblyError(
                f"Quest {quest_id} references missing completion_node_id: {quest.completion_node_id}"
            )


def _validate_map_routes(
    map_routes: dict[str, MapRouteSpec],
    quests: dict[str, QuestSpec],
    nodes: dict[str, NodeSpec],
    scenes: dict[str, SceneSpec],
    challenges: dict[str, ChallengeSpec],
    levels: dict[str, LevelSpec],
) -> None:
    for route_id, route in map_routes.items():
        if route.quest_id not in quests:
            raise GameContentAssemblyError(f"Map route {route_id} references missing quest_id: {route.quest_id}")
        seen_group_ids: set[str] = set()
        for group in route.groups:
            if group.group_id in seen_group_ids:
                raise GameContentAssemblyError(f"Map route {route_id} has duplicate group_id: {group.group_id}")
            seen_group_ids.add(group.group_id)
            _validate_map_route_steps(route_id, group.group_id, group.demo_route, nodes, scenes, challenges, levels)
            _validate_map_route_steps(route_id, group.group_id, group.practice_route, nodes, scenes, challenges, levels)


def _validate_map_route_steps(
    route_id: str,
    group_id: str,
    steps: tuple[MapRouteStepSpec, ...],
    nodes: dict[str, NodeSpec],
    scenes: dict[str, SceneSpec],
    challenges: dict[str, ChallengeSpec],
    levels: dict[str, LevelSpec],
) -> None:
    seen_step_ids: set[str] = set()
    for step in steps:
        if step.step_id in seen_step_ids:
            raise GameContentAssemblyError(
                f"Map route {route_id} group {group_id} has duplicate step_id: {step.step_id}"
            )
        seen_step_ids.add(step.step_id)
        if step.node_id is not None and step.node_id not in nodes:
            raise GameContentAssemblyError(
                f"Map route {route_id} group {group_id} step {step.step_id} references missing node_id: {step.node_id}"
            )
        for node_id in step.tracked_node_ids:
            if node_id not in nodes:
                raise GameContentAssemblyError(
                    f"Map route {route_id} group {group_id} step {step.step_id} references missing tracked_node_id: {node_id}"
                )
        if step.scene_id is not None and step.scene_id not in scenes:
            raise GameContentAssemblyError(
                f"Map route {route_id} group {group_id} step {step.step_id} references missing scene_id: {step.scene_id}"
            )
        if step.challenge_id is not None and step.challenge_id not in challenges:
            raise GameContentAssemblyError(
                f"Map route {route_id} group {group_id} step {step.step_id} references missing challenge_id: {step.challenge_id}"
            )
        for level_id in step.level_ids:
            if level_id not in levels:
                raise GameContentAssemblyError(
                    f"Map route {route_id} group {group_id} step {step.step_id} references missing level_id: {level_id}"
                )


def _resolve_index_path(base_dir: Path) -> Path:
    for name in ("index.yaml", "index.yml", "index.json"):
        candidate = base_dir / name
        if candidate.exists():
            return candidate
    raise GameContentLoadError(f"Missing game content index in {base_dir}")


def _read_structured_file(path: Path) -> Any:
    text = path.read_text(encoding="utf-8")
    if path.suffix.lower() == ".json":
        return json.loads(text)
    if path.suffix.lower() in {".yaml", ".yml"}:
        try:
            import yaml
        except ImportError as exc:  # pragma: no cover
            raise GameContentLoadError("PyYAML is required to load game content YAML") from exc
        return yaml.safe_load(text)
    raise GameContentLoadError(f"Unsupported structured file type: {path}")


def _expect_dict(path: Path, raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise GameContentLoadError(f"{path.name} must contain an object")
    return raw


def _require_list(data: dict[str, Any], key: str, path: Path) -> list[Any]:
    value = data.get(key)
    if not isinstance(value, list):
        raise GameContentLoadError(f"{path.name} must contain a list field: {key}")
    return value


def _require_str(data: dict[str, Any], key: str, *, context: str) -> str:
    value = _optional_str(data.get(key))
    if value is None:
        raise GameContentLoadError(f"{context} missing required field: {key}")
    return value


def _optional_str(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def _optional_int(value: Any) -> int | None:
    if value is None:
        return None
    if isinstance(value, int):
        return value
    try:
        return int(str(value))
    except ValueError:
        raise GameContentLoadError(f"Expected int-compatible value, got: {value!r}") from None


def _require_str_list(value: Any, *, field_name: str, context: str) -> list[str]:
    if not isinstance(value, list):
        raise GameContentLoadError(f"{context} must contain a list field: {field_name}")
    items = [_optional_str(item) for item in value]
    if any(item is None for item in items):
        raise GameContentLoadError(f"{context} contains blank value in {field_name}")
    return [item for item in items if item is not None]


def _require_int_list(value: Any, *, field_name: str, context: str) -> list[int]:
    if not isinstance(value, list):
        raise GameContentLoadError(f"{context} must contain a list field: {field_name}")
    parsed: list[int] = []
    for item in value:
        parsed_item = _optional_int(item)
        if parsed_item is not None:
            parsed.append(parsed_item)
    return parsed


def _metadata_from_raw(raw: dict[str, Any]) -> dict[str, Any]:
    reserved = {
        "scene_id",
        "title",
        "dialogue_blocks",
        "next_action",
        "node_id",
        "node_type",
        "prerequisite_node_ids",
        "next_node_ids",
        "challenge_group_id",
        "quest_id",
        "node_ids",
        "entry_node_id",
        "completion_node_id",
        "challenge_id",
        "challenge_type",
        "level_ids",
        "toolbox_policy_id",
        "battery_policy_id",
        "toolbox_id",
        "unlocked_block_ids",
        "allow_toolbox_in_practice",
        "toolbox_reward_percent",
        "full_reward_percent",
        "pass_threshold_percent",
        "accepted_pass_values",
        "map_routes",
        "route_id",
        "groups",
        "group_id",
        "demo_route",
        "practice_route",
        "step_id",
        "step_type",
        "target_page",
        "tracked_node_ids",
        "is_planned",
        "is_repeatable",
    }
    metadata = raw.get("metadata")
    if isinstance(metadata, dict):
        return dict(metadata)
    return {key: value for key, value in raw.items() if key not in reserved}

from __future__ import annotations

from block2python.contracts import LevelSpec

from .errors import GameContentAssemblyError
from .models import ChallengeSpec, MapRouteSpec, MapRouteStepSpec, NodeSpec, QuestSpec, SceneSpec


_ALLOWED_STEP_TYPES = {"map", "story", "demo", "practice", "map_return"}
_ALLOWED_TARGET_PAGES = {"map", "scene", "demo", "challenge"}
_STEP_TARGET_PAGE_RULES = {
    "story": "scene",
    "demo": "demo",
    "practice": "challenge",
}


def validate_nodes(
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
        if node.mission_statement_scene_id is not None and node.mission_statement_scene_id not in scenes:
            raise GameContentAssemblyError(
                f"Node {node_id} references missing mission_statement_scene_id: {node.mission_statement_scene_id}"
            )
        if node.challenge_group_id is not None and node.challenge_group_id not in challenges:
            raise GameContentAssemblyError(
                f"Node {node_id} references missing challenge_group_id: {node.challenge_group_id}"
            )


def validate_quests(quests: dict[str, QuestSpec], nodes: dict[str, NodeSpec]) -> None:
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


def validate_map_routes(
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
            validate_map_route_steps(route_id, group.group_id, group.demo_route, nodes, scenes, challenges, levels)
            validate_map_route_steps(route_id, group.group_id, group.practice_route, nodes, scenes, challenges, levels)


def validate_map_route_steps(
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
        _validate_map_route_step_shape(route_id, group_id, step)
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


def _validate_map_route_step_shape(route_id: str, group_id: str, step: MapRouteStepSpec) -> None:
    if step.step_type not in _ALLOWED_STEP_TYPES:
        raise GameContentAssemblyError(
            f"Map route {route_id} group {group_id} step {step.step_id} has unsupported step_type: {step.step_type}"
        )
    if step.target_page not in _ALLOWED_TARGET_PAGES:
        raise GameContentAssemblyError(
            f"Map route {route_id} group {group_id} step {step.step_id} has unsupported target_page: {step.target_page}"
        )
    expected_target = _STEP_TARGET_PAGE_RULES.get(step.step_type)
    if expected_target is not None and step.target_page != expected_target:
        raise GameContentAssemblyError(
            f"Map route {route_id} group {group_id} step {step.step_id} must use target_page {expected_target}"
        )
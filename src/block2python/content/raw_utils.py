from __future__ import annotations

from typing import Any

from .errors import GameContentLoadError


def expect_dict(path, raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise GameContentLoadError(f"{path.name} must contain an object")
    return raw


def require_list(data: dict[str, Any], key: str, path) -> list[Any]:
    value = data.get(key)
    if not isinstance(value, list):
        raise GameContentLoadError(f"{path.name} must contain a list field: {key}")
    return value


def require_str(data: dict[str, Any], key: str, *, context: str) -> str:
    value = optional_str(data.get(key))
    if value is None:
        raise GameContentLoadError(f"{context} missing required field: {key}")
    return value


def optional_str(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def optional_int(value: Any) -> int | None:
    if value is None:
        return None
    if isinstance(value, int):
        return value
    try:
        return int(str(value))
    except ValueError:
        raise GameContentLoadError(f"Expected int-compatible value, got: {value!r}") from None


def require_str_list(value: Any, *, field_name: str, context: str) -> list[str]:
    if not isinstance(value, list):
        raise GameContentLoadError(f"{context} must contain a list field: {field_name}")
    items = [optional_str(item) for item in value]
    if any(item is None for item in items):
        raise GameContentLoadError(f"{context} contains blank value in {field_name}")
    return [item for item in items if item is not None]


def require_int_list(value: Any, *, field_name: str, context: str) -> list[int]:
    if not isinstance(value, list):
        raise GameContentLoadError(f"{context} must contain a list field: {field_name}")
    parsed: list[int] = []
    for item in value:
        parsed_item = optional_int(item)
        if parsed_item is not None:
            parsed.append(parsed_item)
    return parsed


def metadata_from_raw(raw: dict[str, Any]) -> dict[str, Any]:
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

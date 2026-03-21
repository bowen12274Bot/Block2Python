from __future__ import annotations

from pathlib import Path

from .errors import GameContentLoadError
from .models import GameContentBundle
from .parsers import (
    parse_battery_file,
    parse_challenge_file,
    parse_map_route_file,
    parse_node_file,
    parse_quest_file,
    parse_scene_file,
    parse_toolbox_file,
)
from .structured_loader import (
    load_group,
    load_map_routes_group,
    load_nodes_group,
    read_structured_file,
    resolve_index_path,
)


def load_game_content(game_content_dir: Path) -> GameContentBundle:
    index_path = resolve_index_path(game_content_dir)
    raw_index = read_structured_file(index_path)
    if not isinstance(raw_index, dict):
        raise GameContentLoadError(f"Index file must be an object: {index_path}")

    return GameContentBundle(
        quests=load_group(raw_index, game_content_dir, "quests", parse_quest_file),
        nodes=load_nodes_group(raw_index, game_content_dir, parse_node_file),
        scenes=load_group(raw_index, game_content_dir, "scenes", parse_scene_file),
        challenges=load_group(raw_index, game_content_dir, "challenges", parse_challenge_file),
        map_routes=load_map_routes_group(raw_index, game_content_dir, parse_map_route_file),
        toolbox=load_group(raw_index, game_content_dir, "toolbox", parse_toolbox_file),
        battery_policies=load_group(raw_index, game_content_dir, "battery", parse_battery_file),
    )

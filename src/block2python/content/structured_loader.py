from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable, TypeVar

from .errors import GameContentLoadError
from .models import MapRouteSpec, NodeSpec

T = TypeVar("T")


def resolve_index_path(base_dir: Path) -> Path:
    for name in ("index.yaml", "index.yml", "index.json"):
        candidate = base_dir / name
        if candidate.exists():
            return candidate
    raise GameContentLoadError(f"Missing game content index in {base_dir}")


def read_structured_file(path: Path) -> Any:
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


def load_group(
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
        file_rel = _require_index_file(item, key)
        path = (base_dir / file_rel).resolve()
        obj_id, obj = parser(path, read_structured_file(path))
        if obj_id in loaded:
            raise GameContentLoadError(f"Duplicate {key} id: {obj_id}")
        loaded[obj_id] = obj
    return loaded


def load_nodes_group(raw_index: dict[str, Any], base_dir: Path, parser: Callable[[Path, Any], tuple[NodeSpec, ...]]) -> dict[str, NodeSpec]:
    items = raw_index.get("nodes", [])
    if not isinstance(items, list):
        raise GameContentLoadError(f"{base_dir.name}/index must contain list field: nodes")

    loaded: dict[str, NodeSpec] = {}
    for item in items:
        if not isinstance(item, dict):
            raise GameContentLoadError("nodes entries must be objects")
        file_rel = _require_index_file(item, "nodes")
        path = (base_dir / file_rel).resolve()
        for node in parser(path, read_structured_file(path)):
            if node.node_id in loaded:
                raise GameContentLoadError(f"Duplicate nodes id: {node.node_id}")
            loaded[node.node_id] = node
    return loaded


def load_map_routes_group(
    raw_index: dict[str, Any],
    base_dir: Path,
    parser: Callable[[Path, Any], tuple[MapRouteSpec, ...]],
) -> dict[str, MapRouteSpec]:
    items = raw_index.get("map_routes", [])
    if not isinstance(items, list):
        raise GameContentLoadError(f"{base_dir.name}/index must contain list field: map_routes")

    loaded: dict[str, MapRouteSpec] = {}
    for item in items:
        if not isinstance(item, dict):
            raise GameContentLoadError("map_routes entries must be objects")
        file_rel = _require_index_file(item, "map_routes")
        path = (base_dir / file_rel).resolve()
        for route in parser(path, read_structured_file(path)):
            if route.route_id in loaded:
                raise GameContentLoadError(f"Duplicate map_routes id: {route.route_id}")
            loaded[route.route_id] = route
    return loaded


def _require_index_file(item: dict[str, Any], context: str) -> str:
    value = item.get("file")
    if value is None:
        raise GameContentLoadError(f"{context} missing required field: file")
    text = str(value).strip()
    if not text:
        raise GameContentLoadError(f"{context} missing required field: file")
    return text

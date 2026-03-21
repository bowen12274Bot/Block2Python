from __future__ import annotations

import json
import shutil
import uuid
from pathlib import Path

import pytest


from block2python.content import (
    GameContentAssemblyError,
    GameContentLoadError,
    GameRuntime,
    GameRuntimeError,
    assemble_game_slice,
    load_game_content,
    load_levels,
)


def test_load_runtime_game_content_assets() -> None:
    bundle = load_game_content(Path("assets/game_content"))

    assert "quest-main-map" in bundle.quests
    assert "main-map-entry" in bundle.nodes
    assert "scene-city-alarm" in bundle.scenes
    assert "challenge-group-01-practice" in bundle.challenges
    assert "toolbox-group-01" in bundle.toolbox
    assert "battery-group-01" in bundle.battery_policies


def test_assemble_runtime_game_slice_against_levels_assets() -> None:
    levels = load_levels(Path("assets/levels"))
    bundle = load_game_content(Path("assets/game_content"))

    assembled = assemble_game_slice(game_content=bundle, levels=levels)
    practice = assembled.challenges["challenge-group-01-practice"]

    assert [level.level_id for level in practice.levels] == [
        "group-01-practice-01",
        "group-01-practice-02",
        "group-01-practice-03",
        "group-01-practice-04",
        "group-01-practice-05",
    ]
    assert practice.toolbox_policy is None
    assert practice.battery_policy is None

    group_02_practice = assembled.challenges["challenge-group-02-practice"]
    assert [level.level_id for level in group_02_practice.levels] == [
        "group-02-practice-01",
        "group-02-practice-02",
        "group-02-practice-03",
        "group-02-practice-04",
        "group-02-practice-05",
    ]
    assert group_02_practice.toolbox_policy is None
    assert group_02_practice.battery_policy is None


def test_missing_level_reference_raises() -> None:
    tmp_path = _make_temp_test_dir()
    try:
        levels_dir = tmp_path / "levels"
        levels_dir.mkdir()
        (levels_dir / "index.json").write_text(
            json.dumps({"levels": [{"id": "l1", "file": "l1.json"}]}),
            encoding="utf-8",
        )
        (levels_dir / "l1.json").write_text(json.dumps({"level_id": "l1", "title": "L1"}), encoding="utf-8")

        content_dir = tmp_path / "game_content"
        _write_game_content_fixture(content_dir, challenge_level_ids=["missing-level"])

        bundle = load_game_content(content_dir)
        levels = load_levels(levels_dir)

        with pytest.raises(GameContentAssemblyError, match="missing level_id"):
            assemble_game_slice(game_content=bundle, levels=levels)
    finally:
        shutil.rmtree(tmp_path, ignore_errors=True)


def test_missing_scene_reference_raises() -> None:
    tmp_path = _make_temp_test_dir()
    try:
        content_dir = tmp_path / "game_content"
        _write_game_content_fixture(content_dir, scene_id="missing-scene")
        bundle = load_game_content(content_dir)

        with pytest.raises(GameContentAssemblyError, match="missing scene_id"):
            assemble_game_slice(game_content=bundle, levels={})
    finally:
        shutil.rmtree(tmp_path, ignore_errors=True)


def test_invalid_index_shape_raises() -> None:
    tmp_path = _make_temp_test_dir()
    try:
        content_dir = tmp_path / "game_content"
        content_dir.mkdir()
        (content_dir / "index.yaml").write_text("quests: nope\n", encoding="utf-8")

        with pytest.raises(GameContentLoadError, match="quests"):
            load_game_content(content_dir)
    finally:
        shutil.rmtree(tmp_path, ignore_errors=True)


def test_game_runtime_walks_runtime_quest() -> None:
    levels = load_levels(Path("assets/levels"))
    bundle = load_game_content(Path("assets/game_content"))
    assembled = assemble_game_slice(game_content=bundle, levels=levels)

    runtime = GameRuntime.start(assembled, quest_id="quest-main-map")

    state = runtime.current_state()
    assert state is not None
    assert state.node.node_id == "main-map-entry"
    assert state.scene is None
    assert state.challenge is None
    assert state.available_next_node_ids == ("group-01-story",)

    runtime.complete_current_node()
    state = runtime.current_state()
    assert state is not None
    assert state.node.node_id == "group-01-story"
    assert state.scene is not None
    assert state.scene.scene_id == "scene-city-alarm"

    runtime.complete_current_node()
    state = runtime.current_state()
    assert state is not None
    assert state.node.node_id == "group-01-demo"
    assert state.scene is None
    assert state.challenge is not None
    assert state.challenge.challenge_id == "challenge-group-01-demo"
def test_game_runtime_rejects_unknown_quest() -> None:
    levels = load_levels(Path("assets/levels"))
    bundle = load_game_content(Path("assets/game_content"))
    assembled = assemble_game_slice(game_content=bundle, levels=levels)

    with pytest.raises(GameRuntimeError, match="Unknown quest_id"):
        GameRuntime.start(assembled, quest_id="missing-quest")


def _write_game_content_fixture(
    base_dir: Path,
    *,
    challenge_level_ids: list[str] | None = None,
    scene_id: str = "scene-1",
) -> None:
    (base_dir / "quests").mkdir(parents=True)
    (base_dir / "nodes").mkdir()
    (base_dir / "scenes").mkdir()
    (base_dir / "challenges").mkdir()
    (base_dir / "toolbox").mkdir()
    (base_dir / "battery").mkdir()

    (base_dir / "index.yaml").write_text(
        "\n".join(
            [
                "quests:",
                "  - file: quests/q.yaml",
                "nodes:",
                "  - file: nodes/n.yaml",
                "scenes:",
                "  - file: scenes/s.yaml",
                "challenges:",
                "  - file: challenges/c.yaml",
                "toolbox: []",
                "battery: []",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    (base_dir / "quests" / "q.yaml").write_text(
        "\n".join(
            [
                "quest_id: q1",
                "title: Quest",
                "node_ids:",
                "  - node-1",
                "entry_node_id: node-1",
                "completion_node_id: node-1",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    (base_dir / "nodes" / "n.yaml").write_text(
        "\n".join(
            [
                "nodes:",
                "  - node_id: node-1",
                "    node_type: story",
                "    title: Node",
                "    prerequisite_node_ids: []",
                "    next_node_ids: []",
                f"    scene_id: {scene_id}",
                "    challenge_group_id: challenge-1",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    (base_dir / "scenes" / "s.yaml").write_text(
        "\n".join(
            [
                "scene_id: scene-1",
                "title: Scene",
                "dialogue_blocks:",
                "  - speaker: Byte",
                "    text: hello",
                "next_action: next",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    level_ids = challenge_level_ids or ["l1"]
    challenge_lines = [
        "challenge_id: challenge-1",
        "challenge_type: demo",
        "title: Challenge",
        "level_ids:",
    ]
    challenge_lines.extend(f"  - {level_id}" for level_id in level_ids)
    challenge_lines.extend(
        [
            "toolbox_policy_id: null",
            "battery_policy_id: null",
        ]
    )
    (base_dir / "challenges" / "c.yaml").write_text("\n".join(challenge_lines) + "\n", encoding="utf-8")


def _make_temp_test_dir() -> Path:
    path = Path(".tmp") / f"test-game-content-{uuid.uuid4().hex}"
    path.mkdir(parents=True, exist_ok=False)
    return path

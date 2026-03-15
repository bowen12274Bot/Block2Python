from __future__ import annotations

import json
from pathlib import Path

import pytest

from block2python.app.levels_loader import load_levels
from block2python.game_content import (
    GameContentAssemblyError,
    GameContentLoadError,
    GameRuntime,
    GameRuntimeError,
    assemble_game_slice,
    load_game_content,
)


def test_load_runtime_game_content_assets() -> None:
    bundle = load_game_content(Path("assets/game_content"))

    assert "quest-basic-io-repair" in bundle.quests
    assert "story-intro" in bundle.nodes
    assert "scene-city-alarm" in bundle.scenes
    assert "challenge-practice-basic-io" in bundle.challenges
    assert "toolbox-basic-io" in bundle.toolbox
    assert "battery-basic-io" in bundle.battery_policies


def test_assemble_runtime_game_slice_against_levels_assets() -> None:
    levels = load_levels(Path("assets/levels"))
    bundle = load_game_content(Path("assets/game_content"))

    assembled = assemble_game_slice(game_content=bundle, levels=levels)
    practice = assembled.challenges["challenge-practice-basic-io"]

    assert [level.level_id for level in practice.levels] == ["practice-basic-io-sum", "practice-basic-io-double"]
    assert practice.toolbox_policy is not None
    assert practice.battery_policy is not None


def test_missing_level_reference_raises(tmp_path: Path) -> None:
    levels_dir = tmp_path / "levels"
    levels_dir.mkdir()
    (levels_dir / "index.json").write_text(json.dumps({"levels": [{"id": "l1", "file": "l1.json"}]}), encoding="utf-8")
    (levels_dir / "l1.json").write_text(json.dumps({"level_id": "l1", "title": "L1"}), encoding="utf-8")

    content_dir = tmp_path / "game_content"
    _write_game_content_fixture(content_dir, challenge_level_ids=["missing-level"])

    bundle = load_game_content(content_dir)
    levels = load_levels(levels_dir)

    with pytest.raises(GameContentAssemblyError, match="missing level_id"):
        assemble_game_slice(game_content=bundle, levels=levels)


def test_missing_scene_reference_raises(tmp_path: Path) -> None:
    content_dir = tmp_path / "game_content"
    _write_game_content_fixture(content_dir, scene_id="missing-scene")
    bundle = load_game_content(content_dir)

    with pytest.raises(GameContentAssemblyError, match="missing scene_id"):
        assemble_game_slice(game_content=bundle, levels={})


def test_invalid_index_shape_raises(tmp_path: Path) -> None:
    content_dir = tmp_path / "game_content"
    content_dir.mkdir()
    (content_dir / "index.yaml").write_text("quests: nope\n", encoding="utf-8")

    with pytest.raises(GameContentLoadError, match="quests"):
        load_game_content(content_dir)


def test_game_runtime_walks_runtime_quest() -> None:
    levels = load_levels(Path("assets/levels"))
    bundle = load_game_content(Path("assets/game_content"))
    assembled = assemble_game_slice(game_content=bundle, levels=levels)

    runtime = GameRuntime.start(assembled, quest_id="quest-basic-io-repair")

    state = runtime.current_state()
    assert state is not None
    assert state.node.node_id == "map-entry"
    assert state.scene is None
    assert state.challenge is None
    assert state.available_next_node_ids == ("story-intro",)

    runtime.complete_current_node()
    state = runtime.current_state()
    assert state is not None
    assert state.node.node_id == "story-intro"
    assert state.scene is not None
    assert state.scene.scene_id == "scene-city-alarm"

    runtime.complete_current_node()
    state = runtime.current_state()
    assert state is not None
    assert state.node.node_id == "demo-basic-io"
    assert state.scene is not None
    assert state.scene.scene_id == "scene-practice-unlock"
    assert state.challenge is not None
    assert state.challenge.challenge_id == "challenge-demo-basic-io"


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

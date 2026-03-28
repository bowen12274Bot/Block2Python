from pathlib import Path

from block2python.content.parsers import parse_scene_file
from block2python.game.scene_progress_projection import SceneProgressProjectionMixin
from block2python.integration.contracts import ActorCueState, DialogueBlockState, GameMode, GameState, SceneState, serialize_game_state


class _ProjectionHarness(SceneProgressProjectionMixin):
    def __init__(self) -> None:
        self.runtime = type("Runtime", (), {})()
        self.runtime.game_slice = type("GameSlice", (), {"scenes": {}})()
        self.demo_seen_group_ids = set()
        self.toolbox_used_level_ids = set()
        self.runtime.quest = type("Quest", (), {"node_ids": ()})()
        self.runtime.completed_node_ids = set()
        self.app = type("App", (), {"is_cleared": staticmethod(lambda _level_id: False)})()

    def _session_error(self, message: str) -> RuntimeError:
        return RuntimeError(message)


def test_parse_scene_dialogue_supports_center_actor_fields() -> None:
    _, scene = parse_scene_file(
        Path("scene-center.yaml"),
        {
            "scene_id": "scene-center",
            "title": "Center Scene",
            "dialogue_blocks": [
                {
                    "speaker": "Byte",
                    "text": "Look here.",
                    "portrait_id": "byte-default",
                    "expression": "alert",
                    "speaker_side": "center",
                    "center_actor": {
                        "actor_id": "byte",
                        "display_name": "Byte",
                        "portrait_id": "byte-default",
                        "expression_id": "alert",
                        "pose_id": "default",
                        "visual_state": "focus",
                    },
                }
            ],
            "next_action": "advance",
        },
    )

    block = scene.dialogue_blocks[0]
    assert block.speaker_side == "center"
    assert block.center_actor is not None
    assert block.center_actor.expression_id == "alert"
    assert block.center_actor.visual_state == "focus"


def test_scene_projection_preserves_actor_cues() -> None:
    harness = _ProjectionHarness()
    _, scene = parse_scene_file(
        Path("scene-center.yaml"),
        {
            "scene_id": "scene-center",
            "title": "Center Scene",
            "dialogue_blocks": [
                {
                    "speaker": "Byte",
                    "text": "Look here.",
                    "portrait_id": "byte-default",
                    "expression": "alert",
                    "speaker_side": "center",
                    "center_actor": {
                        "actor_id": "byte",
                        "display_name": "Byte",
                        "portrait_id": "byte-default",
                        "expression_id": "alert",
                        "pose_id": "default",
                        "visual_state": "focus",
                    },
                }
            ],
            "next_action": "advance",
        },
    )

    state = harness._scene_state(scene)

    assert state is not None
    block = state.dialogue_blocks[0]
    assert block.speaker_side == "center"
    assert block.center_actor is not None
    assert block.center_actor.actor_id == "byte"


def test_serialize_game_state_emits_center_actor_payload() -> None:
    state = GameState(
        mode=GameMode.SCENE,
        quest_id="quest-main-map",
        scene=SceneState(
            scene_id="scene-center",
            title="Center Scene",
            dialogue_blocks=(
                DialogueBlockState(
                    speaker="Byte",
                    text="Look here.",
                    portrait_id="byte-default",
                    expression="alert",
                    speaker_side="center",
                    center_actor=ActorCueState(
                        actor_id="byte",
                        display_name="Byte",
                        portrait_id="byte-default",
                        expression_id="alert",
                        pose_id="default",
                        visual_state="focus",
                    ),
                ),
            ),
        ),
    )

    payload = serialize_game_state(state)
    block = payload["scene"]["dialogue_blocks"][0]

    assert block["speaker_side"] == "center"
    assert block["center_actor"]["expression_id"] == "alert"
    assert block["center_actor"]["visual_state"] == "focus"
import pytest

from block2python.integration.contracts import (
    ActionType,
    AvailableActions,
    ChallengeState,
    DialogueBlockState,
    GameMode,
    GameState,
    IntegrationContractValidationError,
    PlayerAction,
    ProgressState,
    SceneState,
    SubmissionFeedback,
    deserialize_player_action,
    serialize_game_state,
    serialize_player_action,
)


def test_serialize_game_state_emits_json_ready_payload() -> None:
    state = GameState(
        mode=GameMode.CHALLENGE,
        quest_id="quest-main-map",
        node_id="group-01-practice",
        node_title="Group 01 Practice",
        scene=SceneState(
            scene_id="scene-practice-unlock",
            title="Practice Unlock",
            dialogue_blocks=(DialogueBlockState(speaker="Byte", text="Try it."),),
        ),
        challenge=ChallengeState(
            challenge_id="challenge-group-01-practice",
            challenge_type="practice",
            current_level_id="group-01-practice-01",
            current_level_title="Group 01 Practice 01 Hello",
            current_level_prompt="Print a greeting.",
        ),
        progress=ProgressState(
            completed_node_ids=("main-map-entry", "group-01-story"),
            cleared_level_ids=("demo-0",),
            demo_seen_group_ids=("group-01",),
            toolbox_used_level_ids=("group-01-practice-01",),
        ),
        available_actions=AvailableActions(submit=True, restart_quest=True),
        last_submission=SubmissionFeedback(
            level_id="group-01-practice-01",
            cleared=True,
            block_passed=True,
            analysis_status="PASS",
            analysis_summary="OK",
            judge_status="AC",
            judge_summary="Accepted",
            verification_only=False,
            answer_correct=True,
        ),
        errors=("none",),
    )

    payload = serialize_game_state(state)

    assert payload["mode"] == "challenge"
    assert payload["scene"]["scene_id"] == "scene-practice-unlock"
    assert payload["challenge"]["current_level_id"] == "group-01-practice-01"
    assert payload["challenge"]["current_level_prompt"] == "Print a greeting."
    assert payload["progress"]["completed_node_ids"] == ["main-map-entry", "group-01-story"]
    assert payload["progress"]["demo_seen_group_ids"] == ["group-01"]
    assert payload["progress"]["toolbox_used_level_ids"] == ["group-01-practice-01"]
    assert payload["available_actions"] == {
        "advance": False,
        "submit": True,
        "restart_quest": True,
    }
    assert payload["last_submission"]["judge_status"] == "AC"
    assert payload["last_submission"]["verification_only"] is False
    assert payload["last_submission"]["answer_correct"] is True
    assert payload["errors"] == ["none"]


def test_player_action_round_trip_serialize_and_deserialize() -> None:
    action = PlayerAction(
        action_type=ActionType.SUBMIT_LEVEL,
        payload={"python_code": "print(3)\n", "block_json": {"kind": "workspace"}},
    )

    serialized = serialize_player_action(action)
    deserialized = deserialize_player_action(serialized)

    assert deserialized == action


def test_deserialize_player_action_rejects_unknown_action_type() -> None:
    with pytest.raises(IntegrationContractValidationError, match="Unknown PlayerAction.action_type"):
        deserialize_player_action({"action_type": "teleport", "payload": {}})


def test_deserialize_player_action_rejects_invalid_block_json_shape() -> None:
    with pytest.raises(IntegrationContractValidationError, match="block_json"):
        deserialize_player_action(
            {
                "action_type": "submit_level",
                "payload": {"python_code": "print(1)\n", "block_json": ["bad"]},
            }
        )

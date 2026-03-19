from block2python.integration.contracts import (
    ActionType,
    AvailableActions,
    DialogueBlockState,
    GameMode,
    GameState,
    PlayerAction,
    ProgressState,
    SceneState,
    SubmissionFeedback,
)


def test_game_state_contract_supports_scene_payload() -> None:
    state = GameState(
        mode=GameMode.SCENE,
        quest_id="quest-main-map",
        node_id="group-01-story",
        node_title="Group 01 Story",
        scene=SceneState(
            scene_id="scene-city-alarm",
            title="City Alarm",
            dialogue_blocks=(
                DialogueBlockState(speaker="Byte", text="Wake up."),
                DialogueBlockState(speaker="Nova", text="System check.", emphasis="alert"),
            ),
        ),
        progress=ProgressState(completed_node_ids=("main-map-entry",), cleared_level_ids=()),
        available_actions=AvailableActions(advance=True),
        last_submission=SubmissionFeedback(
            level_id="group-01-practice-01",
            cleared=True,
            block_passed=True,
            analysis_status="PASS",
            analysis_summary="OK",
            judge_status="AC",
            judge_summary="Accepted",
        ),
    )

    assert state.mode is GameMode.SCENE
    assert state.scene is not None
    assert state.scene.dialogue_blocks[1].emphasis == "alert"
    assert state.available_actions.advance is True
    assert state.available_actions.submit is False
    assert state.last_submission is not None
    assert state.last_submission.judge_status == "AC"


def test_player_action_contract_supports_submit_payload() -> None:
    action = PlayerAction(
        action_type=ActionType.SUBMIT_LEVEL,
        payload={
            "python_code": "print(1)\n",
            "block_json": {"type": "workspace"},
        },
    )

    assert action.action_type is ActionType.SUBMIT_LEVEL
    assert action.payload["python_code"] == "print(1)\n"

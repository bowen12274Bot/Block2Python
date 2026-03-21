from block2python.integration.contracts import (
    ActionType,
    AvailableActions,
    DemoState,
    DialogueBlockState,
    GameMode,
    GameState,
    PlayerAction,
    PlayerProfileState,
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
        player_profile=PlayerProfileState(name="Nova", gender="female", profile_created=True),
        intro_completed=True,
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
    assert state.player_profile.profile_created is True
    assert state.intro_completed is True
    assert state.player_profile.gender == "female"
    assert state.scene is not None
    assert state.scene.dialogue_blocks[1].emphasis == "alert"
    assert state.available_actions.advance is True
    assert state.available_actions.submit is False
    assert state.last_submission is not None
    assert state.last_submission.judge_status == "AC"


def test_game_state_contract_supports_demo_payload() -> None:
    state = GameState(
        mode=GameMode.DEMO,
        quest_id="quest-main-map",
        node_id="group-01-demo",
        node_title="Group 01 Demo",
        demo=DemoState(
            demo_id="challenge-group-01-demo",
            title="Group 01 Demo",
            body="Placeholder demo body",
            current_level_id="group-01-demo",
        ),
        available_actions=AvailableActions(advance=True),
    )

    assert state.mode is GameMode.DEMO
    assert state.demo is not None
    assert state.demo.demo_id == "challenge-group-01-demo"
    assert state.available_actions.advance is True
    assert state.challenge is None


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


def test_player_action_contract_supports_create_profile_payload() -> None:
    action = PlayerAction(
        action_type=ActionType.CREATE_PLAYER_PROFILE,
        payload={
            "name": "Nova",
            "gender": "female",
        },
    )

    assert action.action_type is ActionType.CREATE_PLAYER_PROFILE
    assert action.payload["name"] == "Nova"
    assert action.payload["gender"] == "female"

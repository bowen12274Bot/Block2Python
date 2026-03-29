from block2python.integration.contracts import (
    ActionType,
    AvailableActions,
    PracticeState,
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
            mission_statement_scene_id="scene-mission-statement-01",
            mission_statement_title="???",
            mission_statement_text="??????????????",
        ),
        progress=ProgressState(completed_node_ids=("main-map-entry",), cleared_level_ids=()),
        available_actions=AvailableActions(advance=True),
        last_submission=SubmissionFeedback(
            level_id="group-01-practice-01",
            cleared=True,
            block_passed=True,
            analysis_status="PASS",
            kind="submission",
            status_label="Passed",
            analysis_summary="OK",
            judge_status="AC",
            judge_summary="Accepted",
            output_text="Submit output:\nanalysis=OK\njudge=Accepted",
        ),
    )

    assert state.mode is GameMode.SCENE
    assert state.player_profile.profile_created is True
    assert state.intro_completed is True
    assert state.player_profile.gender == "female"
    assert state.scene is not None
    assert state.scene.dialogue_blocks[1].emphasis == "alert"
    assert state.scene.mission_statement_scene_id == "scene-mission-statement-01"
    assert state.scene.mission_statement_title == "???"
    assert state.available_actions.advance is True
    assert state.available_actions.submit is False
    assert state.last_submission is not None
    assert state.last_submission.judge_status == "AC"
    assert state.last_submission.status_label == "Passed"


def test_game_state_contract_supports_demo_payload() -> None:
    state = GameState(
        mode=GameMode.DEMO,
        quest_id="quest-main-map",
        node_id="group-01-demo",
        node_title="Group 01 Demo",
        demo=DemoState(
            demo_id="challenge-group-01-demo",
            title="Group 01 Demo",
            group_id="group-01",
            level_id="group-01-demo",
            prompt="Demo prompt",
            learning_markdown="Learn print().",
            story_intro_markdown="Byte explains the task.",
            story_outro_markdown="Next up: practice.",
            can_advance=True,
            body="Demo prompt\n\nLearn print().",
            current_level_id="group-01-demo",
            unlock_blocks=(
                {"title": "print", "description": "Output text to the screen."},
                {"title": "input", "description": "Read user input into your program."},
            ),
            toolbox_block_ids=("text_print", "b2p_input_text"),
        ),
        available_actions=AvailableActions(advance=True),
    )

    assert state.mode is GameMode.DEMO
    assert state.demo is not None
    assert state.demo.demo_id == "challenge-group-01-demo"
    assert state.demo.group_id == "group-01"
    assert state.demo.level_id == "group-01-demo"
    assert state.demo.learning_markdown == "Learn print()."
    assert state.demo.unlock_blocks[0]["title"] == "print"
    assert state.demo.toolbox_block_ids == ("text_print", "b2p_input_text")
    assert state.demo.can_advance is True
    assert state.available_actions.advance is True
    assert state.practice is None


def test_game_state_contract_supports_practice_payload() -> None:
    state = GameState(
        mode=GameMode.CHALLENGE,
        quest_id="quest-main-map",
        node_id="group-01-practice",
        practice=PracticeState(
            challenge_id="challenge-group-01-practice",
            challenge_type="practice",
            group_id="group-01",
            level_id="group-01-practice-01",
            level_title="Input Gate",
            prompt="Read the temperature in Celsius, convert it to Fahrenheit, and print the result.",
            progress_current=1,
            progress_total=5,
            is_review_mode=True,
            toolbox_allowed=True,
            toolbox_used=True,
            toolbox_block_ids=("text_print", "b2p_input_text"),
            can_run=True,
            can_submit=True,
            can_next=False,
            mission_text="Read the temperature in Celsius, convert it to Fahrenheit, and print the result.",
            battery_percent=80,
            battery_threshold_percent=80,
            assistant_messages=("Byte: Read the mission.",),
            current_level_id="group-01-practice-01",
            current_level_title="Input Gate",
            current_level_prompt="Read the temperature in Celsius, convert it to Fahrenheit, and print the result.",
        ),
        available_actions=AvailableActions(run=True, submit=True),
    )

    assert state.practice is not None
    assert state.practice.progress_current == 1
    assert state.practice.progress_total == 5
    assert state.practice.is_review_mode is True
    assert state.practice.toolbox_allowed is True
    assert state.practice.toolbox_used is True
    assert state.practice.toolbox_block_ids == ("text_print", "b2p_input_text")
    assert state.practice.can_run is True
    assert state.practice.can_submit is True
    assert state.practice.can_next is False
    assert state.practice.mission_text == "Read the temperature in Celsius, convert it to Fahrenheit, and print the result."
    assert state.practice.battery_percent == 80
    assert state.practice.assistant_messages == ("Byte: Read the mission.",)


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

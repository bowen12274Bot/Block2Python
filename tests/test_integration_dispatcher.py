from __future__ import annotations

import pytest

from block2python.clients.cli.game_session_demo import build_demo_session
from block2python.integration.contracts import ActionType, GameMode, PlayerAction
from block2python.integration.service import IntegrationDispatchError, dispatch
from tests.test_game_session import build_raw_session


def test_dispatch_advance_returns_next_game_state() -> None:
    session = build_demo_session()

    state = dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))

    assert state.mode is GameMode.SCENE
    assert state.node_id == "group-01-story"
    assert state.scene is not None
    assert state.scene.scene_id == "scene-city-alarm"
    assert state.available_actions.advance is True
    assert state.last_submission is None


def test_dispatch_submit_level_returns_updated_challenge_state() -> None:
    session = build_demo_session()
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))

    state = dispatch(
        session,
        PlayerAction(
            action_type=ActionType.SUBMIT_LEVEL,
            payload={"python_code": "print(3)\n", "block_json": {"kind": "workspace"}},
        ),
    )

    assert state.mode is GameMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.challenge is not None
    assert state.challenge.challenge_id == "challenge-group-01-practice"
    assert state.challenge.current_level_id == "group-01-practice-02"
    assert state.progress.cleared_level_ids == ("group-01-demo", "group-01-practice-01")
    assert state.last_submission is not None
    assert state.last_submission.level_id == "group-01-practice-01"
    assert state.last_submission.judge_status == "AC"


def test_dispatch_verify_toolbox_level_returns_feedback_without_clearing() -> None:
    session = build_demo_session()
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))

    state = dispatch(
        session,
        PlayerAction(
            action_type=ActionType.VERIFY_TOOLBOX_LEVEL,
            payload={"python_code": "print(3)\n", "block_json": {"kind": "toolbox_workspace"}},
        ),
    )

    assert state.mode is GameMode.CHALLENGE
    assert state.challenge is not None
    assert state.challenge.current_level_id == "group-01-practice-01"
    assert state.progress.cleared_level_ids == ("group-01-demo",)
    assert state.progress.toolbox_used_level_ids == ("group-01-practice-01",)
    assert state.last_submission is not None
    assert state.last_submission.verification_only is True
    assert state.last_submission.answer_correct is True
    assert state.last_submission.cleared is False


def test_dispatch_rejects_submit_without_python_code() -> None:
    session = build_demo_session()
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))

    with pytest.raises(IntegrationDispatchError, match="python_code"):
        dispatch(session, PlayerAction(action_type=ActionType.SUBMIT_LEVEL, payload={}))


def test_dispatch_start_group_story_opens_story_scene() -> None:
    session = build_demo_session()

    state = dispatch(
        session,
        PlayerAction(action_type=ActionType.START_GROUP_STORY, payload={"group_id": "group-01"}),
    )

    assert state.mode is GameMode.SCENE
    assert state.node_id == "group-01-story"
    assert state.scene is not None
    assert state.scene.scene_id == "scene-city-alarm"
    assert state.progress.demo_seen_group_ids == ()
    assert state.map_route is not None
    group = state.map_route.groups[0]
    practice_step = next(step for step in group.practice_route if step.step_type == "practice")
    assert practice_step.status_key == "locked"


def test_dispatch_start_group_demo_requires_story_completion() -> None:
    session = build_demo_session()

    with pytest.raises(IntegrationDispatchError, match="story"):
        dispatch(
            session,
            PlayerAction(action_type=ActionType.START_GROUP_DEMO, payload={"group_id": "group-01"}),
        )


def test_dispatch_start_group_demo_opens_demo_node() -> None:
    session = build_demo_session()
    dispatch(session, PlayerAction(action_type=ActionType.START_GROUP_STORY, payload={"group_id": "group-01"}))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))

    state = dispatch(
        session,
        PlayerAction(action_type=ActionType.START_GROUP_DEMO, payload={"group_id": "group-01"}),
    )

    assert state.mode is GameMode.SCENE
    assert state.node_id == "group-01-demo"
    assert state.scene is not None
    assert state.scene.scene_id == "scene-practice-unlock"
    assert state.progress.demo_seen_group_ids == ("group-01",)


def test_dispatch_start_group_practice_rejects_locked_group() -> None:
    session = build_demo_session()

    with pytest.raises(IntegrationDispatchError, match="locked"):
        dispatch(
            session,
            PlayerAction(action_type=ActionType.START_GROUP_PRACTICE, payload={"group_id": "group-01"}),
        )


def test_dispatch_start_group_practice_opens_practice_entry() -> None:
    session = build_demo_session()
    dispatch(session, PlayerAction(action_type=ActionType.START_GROUP_STORY, payload={"group_id": "group-01"}))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))
    dispatch(session, PlayerAction(action_type=ActionType.START_GROUP_DEMO, payload={"group_id": "group-01"}))

    state = dispatch(
        session,
        PlayerAction(action_type=ActionType.START_GROUP_PRACTICE, payload={"group_id": "group-01"}),
    )

    assert state.mode is GameMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.challenge is not None
    assert state.challenge.challenge_id == "challenge-group-01-practice"
    assert state.challenge.current_level_id == "group-01-practice-01"


def test_dispatch_create_player_profile_updates_game_state_and_opens_intro() -> None:
    session = build_raw_session()

    state = dispatch(
        session,
        PlayerAction(
            action_type=ActionType.CREATE_PLAYER_PROFILE,
            payload={"name": " Nova ", "gender": "female"},
        ),
    )

    assert state.player_profile.profile_created is True
    assert state.player_profile.name == "Nova"
    assert state.player_profile.gender == "female"
    assert state.intro_completed is False
    assert state.mode is GameMode.SCENE
    assert state.scene is not None
    assert state.scene.scene_id == "opening-intro"


def test_dispatch_complete_intro_enters_map_flow() -> None:
    session = build_raw_session()
    dispatch(session, PlayerAction(action_type=ActionType.CREATE_PLAYER_PROFILE, payload={"name": "Nova", "gender": "female"}))

    state = dispatch(session, PlayerAction(action_type=ActionType.COMPLETE_INTRO, payload={}))

    assert state.intro_completed is True
    assert state.mode is GameMode.SCENE
    assert state.node_id == "main-map-entry"
    assert state.scene is None


def test_dispatch_create_player_profile_rejects_blank_name() -> None:
    session = build_raw_session()

    with pytest.raises(IntegrationDispatchError, match="player name"):
        dispatch(
            session,
            PlayerAction(
                action_type=ActionType.CREATE_PLAYER_PROFILE,
                payload={"name": "   ", "gender": "male"},
            ),
        )


def test_dispatch_create_player_profile_rejects_invalid_gender() -> None:
    session = build_raw_session()

    with pytest.raises(IntegrationDispatchError, match="player gender"):
        dispatch(
            session,
            PlayerAction(
                action_type=ActionType.CREATE_PLAYER_PROFILE,
                payload={"name": "Nova", "gender": "robot"},
            ),
        )


def test_dispatch_rejects_restart_until_supported() -> None:
    session = build_demo_session()

    with pytest.raises(IntegrationDispatchError, match="not implemented"):
        dispatch(session, PlayerAction(action_type=ActionType.RESTART_QUEST))

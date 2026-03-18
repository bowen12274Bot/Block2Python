from __future__ import annotations

import pytest

from block2python.clients.cli.game_session_demo import build_demo_session
from block2python.integration.contracts import ActionType, GameMode, PlayerAction
from block2python.integration.service import IntegrationDispatchError, dispatch


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
    assert state.challenge is not None
    assert state.challenge.challenge_id == "challenge-group-01-practice"
    assert state.challenge.current_level_id == "group-01-practice-01"
    assert state.progress.cleared_level_ids == ("group-01-demo",)
    assert state.last_submission is not None
    assert state.last_submission.level_id == "group-01-demo"
    assert state.last_submission.judge_status == "AC"


def test_dispatch_rejects_submit_without_python_code() -> None:
    session = build_demo_session()
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))
    dispatch(session, PlayerAction(action_type=ActionType.ADVANCE))

    with pytest.raises(IntegrationDispatchError, match="python_code"):
        dispatch(session, PlayerAction(action_type=ActionType.SUBMIT_LEVEL, payload={}))


def test_dispatch_rejects_restart_until_supported() -> None:
    session = build_demo_session()

    with pytest.raises(IntegrationDispatchError, match="not implemented"):
        dispatch(session, PlayerAction(action_type=ActionType.RESTART_QUEST))

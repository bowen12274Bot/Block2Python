from __future__ import annotations

from block2python.app.core import AppCore
from block2python.app.game_session import GameSession, GameSessionError, SessionMode
from block2python.app.levels_loader import load_levels
from block2python.game_content import assemble_game_slice, load_game_content
from block2python.integration.contracts import GameMode
from block2python.judge import StubJudge


def test_game_session_walks_scene_and_challenge_flow() -> None:
    levels = load_levels(load_levels_dir())
    levels["demo-basic-io-hello"].metadata["stub_judge"] = {"status": "AC"}
    app = AppCore(levels, judge=StubJudge())
    assembled = assemble_game_slice(game_content=load_game_content(game_content_dir()), levels=levels)

    session = GameSession.start(app=app, game_slice=assembled, quest_id="quest-basic-io-repair")

    state = session.current_state()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "map-entry"
    assert state.scene_id is None

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "map-entry"
    assert contract_state.scene is None
    assert contract_state.challenge is None
    assert contract_state.available_actions.advance is True
    assert contract_state.progress.completed_node_ids == ()
    assert contract_state.last_submission is None

    state = session.advance()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "story-intro"
    assert state.scene_id == "scene-city-alarm"

    contract_state = session.current_game_state()
    assert contract_state.scene is not None
    assert contract_state.scene.scene_id == "scene-city-alarm"
    assert contract_state.scene.dialogue_blocks
    assert contract_state.challenge is None

    state = session.advance()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "demo-basic-io"
    assert state.scene_id == "scene-practice-unlock"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.scene is not None
    assert contract_state.scene.scene_id == "scene-practice-unlock"
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-demo-basic-io"

    state = session.advance()
    assert state.mode is SessionMode.CHALLENGE
    assert state.challenge_id == "challenge-demo-basic-io"
    assert state.current_level_id == "demo-basic-io-hello"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.CHALLENGE
    assert contract_state.scene is None
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-demo-basic-io"
    assert contract_state.challenge.current_level_id == "demo-basic-io-hello"
    assert contract_state.available_actions.submit is True

    state, outcome = session.submit_current_level(python_code="name = input()\nprint(\"Hello, \" + name)")
    assert outcome.cleared is True
    assert state.mode is SessionMode.CHALLENGE
    assert state.current_level_id == "practice-basic-io-sum"
    assert state.challenge_id == "challenge-practice-basic-io"

    contract_state = session.current_game_state()
    assert contract_state.progress.completed_node_ids == ("map-entry", "story-intro", "demo-basic-io")
    assert contract_state.progress.cleared_level_ids == ("demo-basic-io-hello",)
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-practice-basic-io"
    assert contract_state.challenge.current_level_id == "practice-basic-io-sum"
    assert contract_state.last_submission is not None
    assert contract_state.last_submission.level_id == "demo-basic-io-hello"
    assert contract_state.last_submission.analysis_status == "PASS"
    assert contract_state.last_submission.judge_status == "AC"


def test_game_session_rejects_advance_during_challenge() -> None:
    levels = load_levels(load_levels_dir())
    app = AppCore(levels, judge=StubJudge())
    assembled = assemble_game_slice(game_content=load_game_content(game_content_dir()), levels=levels)
    session = GameSession.start(app=app, game_slice=assembled, quest_id="quest-basic-io-repair")

    session.advance()
    session.advance()
    session.advance()

    try:
        session.advance()
    except GameSessionError as exc:
        assert "Cannot advance" in str(exc)
    else:
        raise AssertionError("Expected GameSessionError")


def load_levels_dir():
    from pathlib import Path

    return Path("assets/levels")


def game_content_dir():
    from pathlib import Path

    return Path("assets/game_content")

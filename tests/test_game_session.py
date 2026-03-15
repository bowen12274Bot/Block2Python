from __future__ import annotations

from block2python.app.core import AppCore
from block2python.app.game_session import GameSession, GameSessionError, SessionMode
from block2python.app.levels_loader import load_levels
from block2python.game_content import assemble_game_slice, load_game_content
from block2python.judge import StubJudge


def test_game_session_walks_scene_and_challenge_flow() -> None:
    levels = load_levels(load_levels_dir())
    levels["demo-1"].metadata["stub_judge"] = {"status": "AC"}
    app = AppCore(levels, judge=StubJudge())
    assembled = assemble_game_slice(game_content=load_game_content(game_content_dir()), levels=levels)

    session = GameSession.start(app=app, game_slice=assembled, quest_id="quest-basic-io-repair")

    state = session.current_state()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "map-entry"
    assert state.scene_id is None

    state = session.advance()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "story-intro"
    assert state.scene_id == "scene-city-alarm"

    state = session.advance()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "demo-basic-io"
    assert state.scene_id == "scene-practice-unlock"

    state = session.advance()
    assert state.mode is SessionMode.CHALLENGE
    assert state.challenge_id == "challenge-demo-basic-io"
    assert state.current_level_id == "demo-1"

    state, outcome = session.submit_current_level(python_code="print(3)")
    assert outcome.cleared is True
    assert state.mode is SessionMode.CHALLENGE
    assert state.current_level_id == "add-two-numbers"
    assert state.challenge_id == "challenge-practice-basic-io"


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

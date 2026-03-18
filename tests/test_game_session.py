from __future__ import annotations

from block2python.level_play import AppCore
from block2python.content import assemble_game_slice, load_game_content, load_levels
from block2python.game import GameSession, GameSessionError, SessionMode

from block2python.integration.contracts import GameMode
from block2python.judge import StubJudge


def test_game_session_walks_scene_and_challenge_flow() -> None:
    levels = load_levels(load_levels_dir())
    levels["group-01-demo"].metadata["stub_judge"] = {"status": "AC"}
    app = AppCore(levels, judge=StubJudge())
    assembled = assemble_game_slice(game_content=load_game_content(game_content_dir()), levels=levels)

    session = GameSession.start(app=app, game_slice=assembled, quest_id="quest-main-map")

    state = session.current_state()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "main-map-entry"
    assert state.scene_id is None

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "main-map-entry"
    assert contract_state.scene is None
    assert contract_state.challenge is None
    assert contract_state.available_actions.advance is True
    assert contract_state.progress.completed_node_ids == ()
    assert contract_state.last_submission is None

    state = session.advance()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "group-01-story"
    assert state.scene_id == "scene-city-alarm"

    contract_state = session.current_game_state()
    assert contract_state.scene is not None
    assert contract_state.scene.scene_id == "scene-city-alarm"
    assert contract_state.scene.dialogue_blocks
    assert contract_state.challenge is None

    state = session.advance()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "group-01-demo"
    assert state.scene_id == "scene-practice-unlock"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.scene is not None
    assert contract_state.scene.scene_id == "scene-practice-unlock"
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-group-01-demo"

    state = session.advance()
    assert state.mode is SessionMode.CHALLENGE
    assert state.challenge_id == "challenge-group-01-demo"
    assert state.current_level_id == "group-01-demo"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.CHALLENGE
    assert contract_state.scene is None
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-group-01-demo"
    assert contract_state.challenge.current_level_id == "group-01-demo"
    assert contract_state.available_actions.submit is True

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.mode is SessionMode.CHALLENGE
    assert state.current_level_id == "group-01-practice-01"
    assert state.challenge_id == "challenge-group-01-practice"

    contract_state = session.current_game_state()
    assert contract_state.progress.completed_node_ids == ("main-map-entry", "group-01-story", "group-01-demo")
    assert contract_state.progress.cleared_level_ids == ("group-01-demo",)
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-group-01-practice"
    assert contract_state.challenge.current_level_id == "group-01-practice-01"
    assert contract_state.last_submission is not None
    assert contract_state.last_submission.level_id == "group-01-demo"
    assert contract_state.last_submission.analysis_status == "PASS"
    assert contract_state.last_submission.judge_status == "AC"


def test_game_session_rejects_advance_during_challenge() -> None:
    levels = load_levels(load_levels_dir())
    app = AppCore(levels, judge=StubJudge())
    assembled = assemble_game_slice(game_content=load_game_content(game_content_dir()), levels=levels)
    session = GameSession.start(app=app, game_slice=assembled, quest_id="quest-main-map")

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


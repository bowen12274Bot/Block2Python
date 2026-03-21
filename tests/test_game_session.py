from __future__ import annotations

import pytest

from block2python.level_play import AppCore
from block2python.content import assemble_game_slice, load_game_content, load_levels
from block2python.game import GameSession, GameSessionError, SessionMode
from block2python.integration.contracts import GameMode
from block2python.judge import StubJudge


def _progress_until(session: GameSession, stop) -> None:
    while True:
        state = session.current_state()
        if stop(state):
            return
        if state.mode is SessionMode.SCENE:
            if state.node_id == "main-map-entry":
                completed = set(session.current_game_state().progress.completed_node_ids)
                if "group-02-result" in completed:
                    session.start_group_story("group-03")
                elif "group-01-result" in completed:
                    session.start_group_story("group-02")
                else:
                    session.advance()
            else:
                session.advance()
        else:
            session.submit_current_level(python_code="print(1)")


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
    assert contract_state.player_profile.profile_created is False
    assert contract_state.scene is None
    assert contract_state.challenge is None
    assert contract_state.available_actions.advance is True
    assert contract_state.progress.completed_node_ids == ()
    assert contract_state.progress.demo_seen_group_ids == ()
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
    assert contract_state.progress.demo_seen_group_ids == ()

    state = session.advance()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "group-01-demo"
    assert state.scene_id == "scene-practice-unlock"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.scene is not None
    assert contract_state.scene.scene_id == "scene-practice-unlock"
    assert contract_state.progress.demo_seen_group_ids == ("group-01",)
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-group-01-demo"

    state = session.advance()
    assert state.mode is SessionMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.challenge_id == "challenge-group-01-practice"
    assert state.current_level_id == "group-01-practice-01"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.CHALLENGE
    assert contract_state.scene is None
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-group-01-practice"
    assert contract_state.challenge.current_level_id == "group-01-practice-01"
    assert contract_state.available_actions.submit is True
    assert contract_state.progress.completed_node_ids == ("main-map-entry", "group-01-story", "group-01-demo")
    assert contract_state.progress.cleared_level_ids == ("group-01-demo",)

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.mode is SessionMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.challenge_id == "challenge-group-01-practice"
    assert state.current_level_id == "group-01-practice-02"

    contract_state = session.current_game_state()
    assert contract_state.progress.completed_node_ids == ("main-map-entry", "group-01-story", "group-01-demo")
    assert contract_state.progress.cleared_level_ids == ("group-01-demo", "group-01-practice-01")
    assert contract_state.progress.demo_seen_group_ids == ("group-01",)
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-group-01-practice"
    assert contract_state.challenge.current_level_id == "group-01-practice-02"
    assert contract_state.last_submission is not None
    assert contract_state.last_submission.level_id == "group-01-practice-01"
    assert contract_state.last_submission.analysis_status == "PASS"
    assert contract_state.last_submission.judge_status == "AC"


def test_game_session_create_player_profile_persists_in_contract_state() -> None:
    session = build_raw_session()

    contract_state = session.create_player_profile(name=" Nova ", gender="female")

    assert contract_state.player_profile.profile_created is True
    assert contract_state.player_profile.name == "Nova"
    assert contract_state.player_profile.gender == "female"
    assert contract_state.intro_completed is False
    assert contract_state.scene is not None
    assert contract_state.scene.scene_id == "opening-intro"
    assert contract_state.progress.completed_node_ids == ()

    next_state = session.current_game_state()
    assert next_state.player_profile.profile_created is True
    assert next_state.intro_completed is False
    assert next_state.player_profile.name == "Nova"


def test_game_session_create_player_profile_rejects_invalid_payload() -> None:
    session = build_raw_session()

    with pytest.raises(GameSessionError, match="player name"):
        session.create_player_profile(name="   ", gender="female")

    with pytest.raises(GameSessionError, match="player gender"):
        session.create_player_profile(name="Nova", gender="robot")


def test_game_session_complete_intro_enters_main_map_flow() -> None:
    session = build_raw_session()
    session.create_player_profile(name="Nova", gender="female")

    contract_state = session.complete_intro()

    assert contract_state.intro_completed is True
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "main-map-entry"
    assert contract_state.scene is None


def test_game_session_blocks_main_flow_until_intro_is_completed() -> None:
    session = build_raw_session()
    session.create_player_profile(name="Nova", gender="female")

    with pytest.raises(GameSessionError, match="opening intro"):
        session.start_group_story("group-01")



def test_game_session_start_group_story_jumps_to_story() -> None:
    session = build_session()

    state = session.start_group_story("group-01")
    contract_state = session.current_game_state()

    assert state.mode is SessionMode.SCENE
    assert state.node_id == "group-01-story"
    assert state.scene_id == "scene-city-alarm"
    assert contract_state.progress.demo_seen_group_ids == ()
    assert contract_state.scene is not None
    assert contract_state.scene.scene_id == "scene-city-alarm"


def test_game_session_start_group_demo_requires_story_completion() -> None:
    session = build_session()

    with pytest.raises(GameSessionError, match="story"):
        session.start_group_demo("group-01")


def test_game_session_start_group_demo_jumps_to_demo_scene() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()

    state = session.start_group_demo("group-01")
    contract_state = session.current_game_state()

    assert state.mode is SessionMode.SCENE
    assert state.node_id == "group-01-demo"
    assert state.scene_id == "scene-practice-unlock"
    assert contract_state.progress.demo_seen_group_ids == ("group-01",)
    assert contract_state.scene is not None
    assert contract_state.scene.scene_id == "scene-practice-unlock"
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-group-01-demo"



def test_game_session_start_group_practice_requires_demo_seen() -> None:
    session = build_session()

    with pytest.raises(GameSessionError, match="locked"):
        session.start_group_practice("group-01")


def test_game_session_start_group_practice_jumps_to_challenge() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()
    session.start_group_demo("group-01")

    state = session.start_group_practice("group-01")
    contract_state = session.current_game_state()

    assert state.mode is SessionMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.challenge_id == "challenge-group-01-practice"
    assert state.current_level_id == "group-01-practice-01"
    assert contract_state.challenge is not None
    assert contract_state.challenge.challenge_id == "challenge-group-01-practice"
    assert contract_state.challenge.current_level_id == "group-01-practice-01"



def test_game_session_can_complete_all_three_groups() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-03-result")

    state = session.advance()
    assert state.node_id == "main-map-entry"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "main-map-entry"
    assert contract_state.available_actions.advance is False
    assert contract_state.progress.completed_node_ids == (
        "main-map-entry",
        "group-01-story",
        "group-01-demo",
        "group-01-practice",
        "group-01-result",
        "group-02-story",
        "group-02-demo",
        "group-02-practice",
        "group-02-result",
        "group-03-story",
        "group-03-demo",
        "group-03-practice",
        "group-03-result",
    )
    assert contract_state.progress.cleared_level_ids == (
        "group-01-demo",
        "group-01-practice-01",
        "group-01-practice-02",
        "group-01-practice-03",
        "group-01-practice-04",
        "group-01-practice-05",
        "group-02-demo",
        "group-02-practice-01",
        "group-02-practice-02",
        "group-02-practice-03",
        "group-02-practice-04",
        "group-02-practice-05",
        "group-03-demo",
        "group-03-practice-01",
        "group-03-practice-02",
        "group-03-practice-03",
        "group-03-practice-04",
        "group-03-practice-05",
    )
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"
    assert status_by_group["group-02"] == "completed"
    assert status_by_group["group-03"] == "completed"

def test_map_route_marks_only_one_group_current_for_shared_story_scene() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-02-story")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: next(step.status_key for step in group.demo_route if step.step_type == "story") for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] != "current"
    assert status_by_group["group-02"] == "current"
    assert status_by_group["group-03"] != "current"

def test_initial_map_marks_group_one_available_not_current() -> None:
    session = build_session()

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "available"
    assert status_by_group["group-02"] == "locked"
    assert status_by_group["group-03"] == "locked"


def test_group_one_result_returns_to_main_map_entry() -> None:
    session = build_session()

    while True:
        state = session.current_state()
        if state.node_id == "group-01-result":
            break
        if state.mode is SessionMode.SCENE:
            session.advance()
        else:
            session.submit_current_level(python_code="print(1)")

    state = session.advance()
    assert state.node_id == "main-map-entry"

    runtime_state = session.runtime.current_state()
    assert runtime_state is not None
    assert runtime_state.node.node_id == "main-map-entry"
    assert runtime_state.available_next_node_ids == ("group-01-story", "group-02-story")

    contract_state = session.current_game_state()
    assert contract_state.available_actions.advance is False
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"
    assert status_by_group["group-02"] == "available"
    assert status_by_group["group-03"] == "locked"


def test_group_three_result_returns_to_main_map_entry() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-03-result")

    state = session.advance()
    assert state.node_id == "main-map-entry"

    runtime_state = session.runtime.current_state()
    assert runtime_state is not None
    assert runtime_state.node.node_id == "main-map-entry"
    assert runtime_state.available_next_node_ids == ("group-01-story", "group-02-story", "group-03-story")

    contract_state = session.current_game_state()
    assert contract_state.available_actions.advance is False
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"
    assert status_by_group["group-02"] == "completed"
    assert status_by_group["group-03"] == "completed"


def test_group_two_becomes_available_after_group_one_completion() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-02-story")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"
    assert status_by_group["group-02"] == "current"
    assert status_by_group["group-03"] == "locked"


def test_group_story_does_not_unlock_practice_until_demo_node_is_reached() -> None:
    session = build_session()

    while True:
        state = session.current_state()
        if state.node_id == "main-map-entry" and "group-01-result" in set(session.current_game_state().progress.completed_node_ids):
            break
        if state.mode is SessionMode.SCENE:
            session.advance()
        else:
            session.submit_current_level(python_code="print(1)")

    state = session.start_group_story("group-02")
    assert state.node_id == "group-02-story"

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    group_two = next(group for group in contract_state.map_route.groups if group.group_id == "group-02")
    assert group_two.demo_slot is not None
    assert group_two.practice_slot is not None
    assert group_two.demo_slot.viewed is False
    assert group_two.practice_slot.is_unlocked is False

    session.advance()
    contract_state = session.current_game_state()
    group_two = next(group for group in contract_state.map_route.groups if group.group_id == "group-02")
    assert group_two.demo_slot is not None
    assert group_two.practice_slot is not None
    assert group_two.demo_slot.viewed is True
    assert group_two.practice_slot.is_unlocked is True


def test_group_can_complete_after_entering_demo_without_finishing_demo_node() -> None:
    session = build_session()

    session.start_group_story("group-01")
    session.advance()
    session.start_group_practice("group-01")

    while True:
        state = session.current_state()
        if state.node_id == "group-01-result":
            break
        if state.mode is SessionMode.SCENE:
            session.advance()
        else:
            session.submit_current_level(python_code="print(1)")

    session.advance()
    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    group_one = next(group for group in contract_state.map_route.groups if group.group_id == "group-01")
    assert group_one.status_key == "completed"


def test_completed_group_switches_to_reviewing_when_reentering_practice() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-02-story")

    state = session.start_group_practice("group-01")
    assert state.node_id == "group-01-practice"

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "reviewing"
    assert status_by_group["group-02"] == "current"


def test_replaying_completed_group_does_not_relock_later_groups() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-03-practice" and state.current_level_id == "group-03-practice-03")

    session.start_group_practice("group-01")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "reviewing"
    assert status_by_group["group-02"] == "completed"
    assert status_by_group["group-03"] == "current"


def test_all_groups_completed_then_replay_marks_only_replayed_group_reviewing() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-03-result")
    session.advance()

    session.start_group_practice("group-01")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "reviewing"
    assert status_by_group["group-02"] == "completed"
    assert status_by_group["group-03"] == "completed"


def test_reviewing_practice_advances_to_next_level() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-03-result")
    session.advance()

    state = session.start_group_practice("group-01")
    assert state.current_level_id == "group-01-practice-01"

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.node_id == "group-01-practice"
    assert state.current_level_id == "group-01-practice-02"


def test_reviewing_current_game_state_advances_to_third_level_after_second_submit() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-03-result")
    session.advance()

    session.start_group_practice("group-01")
    session.submit_current_level(python_code="print(1)")
    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.current_level_id == "group-01-practice-03"

    contract_state = session.current_game_state()
    assert contract_state.challenge is not None
    assert contract_state.challenge.current_level_id == "group-01-practice-03"


def test_reviewing_practice_fifth_level_returns_to_main_map() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-03-result")
    session.advance()

    session.start_group_practice("group-01")
    for _ in range(4):
        state, outcome = session.submit_current_level(python_code="print(1)")
        assert outcome.cleared is True
        assert state.mode is SessionMode.CHALLENGE

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "main-map-entry"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "main-map-entry"
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"


def test_reviewing_group_does_not_clear_current_from_unfinished_mainline_group() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-02-practice" and state.current_level_id == "group-02-practice-03")

    session.start_group_practice("group-01")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "reviewing"
    assert status_by_group["group-02"] == "current"
    assert status_by_group["group-03"] == "locked"


def test_finishing_review_keeps_current_on_unfinished_mainline_group() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-02-practice" and state.current_level_id == "group-02-practice-03")
    session.start_group_practice("group-01")
    for _ in range(5):
        session.submit_current_level(python_code="print(1)")

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "main-map-entry"
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"
    assert status_by_group["group-02"] == "current"
    assert status_by_group["group-03"] == "locked"


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


def test_toolbox_verification_tracks_usage_without_clearing_level() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()
    session.advance()

    state, outcome = session.verify_current_level_with_toolbox(
        python_code="name = input()\nprint(f\"Hello, {name}\")\n",
        block_json={"kind": "toolbox_workspace", "blocks": [{"type": "print_expr", "expr": "Hello"}]},
    )

    assert state.mode is SessionMode.CHALLENGE
    assert state.current_level_id == "group-01-practice-01"
    assert outcome.cleared is False
    assert outcome.judge.status.value == "AC"

    contract_state = session.current_game_state()
    assert contract_state.progress.cleared_level_ids == ("group-01-demo",)
    assert contract_state.progress.toolbox_used_level_ids == ("group-01-practice-01",)
    assert contract_state.last_submission is not None
    assert contract_state.last_submission.verification_only is True
    assert contract_state.last_submission.answer_correct is True
    assert contract_state.last_submission.cleared is False

    state, outcome = session.submit_current_level(python_code="name = input()\nprint(f\"Hello, {name}\")\n")
    assert outcome.cleared is True
    assert state.current_level_id == "group-01-practice-02"


def build_raw_session() -> GameSession:
    levels = load_levels(load_levels_dir())
    app = AppCore(levels, judge=StubJudge())
    assembled = assemble_game_slice(game_content=load_game_content(game_content_dir()), levels=levels)
    return GameSession.start(app=app, game_slice=assembled, quest_id="quest-main-map")


def build_session() -> GameSession:
    session = build_raw_session()
    session.create_player_profile(name="Test Player", gender="male")
    session.complete_intro()
    return session


def load_levels_dir():
    from pathlib import Path

    return Path("assets/levels")


def game_content_dir():
    from pathlib import Path

    return Path("assets/game_content")


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
        if state.mode in {SessionMode.SCENE, SessionMode.DEMO}:
            if state.node_id == "main-map-entry":
                completed = set(session.current_game_state().progress.completed_node_ids)
                if "group-04-result" in completed:
                    session.start_group_story("group-05")
                elif "group-03-result" in completed:
                    session.start_group_story("group-04")
                elif "group-02-result" in completed:
                    session.start_group_story("group-03")
                elif "group-01-result" in completed:
                    session.start_group_story("group-02")
                else:
                    session.advance()
            else:
                session.advance()
        else:
            _submit_and_progress(session)


def _submit_and_progress(session: GameSession) -> tuple[object, object]:
    state, outcome = session.submit_current_level(python_code="print(1)")
    if outcome.cleared and state.mode is SessionMode.CHALLENGE:
        state = session.next_practice_level()
    return state, outcome


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
    assert contract_state.practice is None
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
    assert contract_state.practice is None
    assert contract_state.progress.demo_seen_group_ids == ()

    state = session.advance()
    assert state.mode is SessionMode.DEMO
    assert state.node_id == "group-01-demo"
    assert state.scene_id is None
    assert state.demo_id == "challenge-group-01-demo"
    assert state.current_level_id == "group-01-demo"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.DEMO
    assert contract_state.scene is None
    assert contract_state.demo is not None
    assert contract_state.demo.demo_id == "challenge-group-01-demo"
    assert contract_state.demo.group_id == "group-01"
    assert contract_state.demo.level_id == "group-01-demo"
    assert contract_state.demo.learning_markdown != ""
    assert contract_state.demo.current_level_id == "group-01-demo"
    assert contract_state.progress.demo_seen_group_ids == ("group-01",)
    assert contract_state.practice is None

    state = session.advance()
    assert state.mode is SessionMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.challenge_id == "challenge-group-01-practice"
    assert state.current_level_id == "group-01-practice-01"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.CHALLENGE
    assert contract_state.scene is None
    assert contract_state.practice is not None
    assert contract_state.practice.challenge_id == "challenge-group-01-practice"
    assert contract_state.practice.current_level_id == "group-01-practice-01"
    assert contract_state.practice.battery_percent == 0
    assert contract_state.practice.progress_current == 1
    assert contract_state.practice.progress_total == 5
    assert contract_state.practice.toolbox_allowed is True
    assert contract_state.practice.toolbox_used is False
    assert contract_state.practice.can_submit is True
    assert contract_state.available_actions.submit is True
    assert contract_state.progress.completed_node_ids == ("main-map-entry", "group-01-story", "group-01-demo")
    assert contract_state.progress.cleared_level_ids == ()

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.mode is SessionMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.challenge_id == "challenge-group-01-practice"
    assert state.current_level_id == "group-01-practice-01"

    contract_state = session.current_game_state()
    assert contract_state.progress.completed_node_ids == ("main-map-entry", "group-01-story", "group-01-demo")
    assert contract_state.progress.cleared_level_ids == ("group-01-practice-01",)
    assert contract_state.progress.demo_seen_group_ids == ("group-01",)
    assert contract_state.practice is not None
    assert contract_state.practice.challenge_id == "challenge-group-01-practice"
    assert contract_state.practice.current_level_id == "group-01-practice-01"
    assert contract_state.practice.battery_percent == 20
    assert contract_state.practice.progress_current == 1
    assert contract_state.practice.toolbox_used is False
    assert contract_state.practice.can_next is True
    assert contract_state.last_submission is not None
    assert contract_state.last_submission.level_id == "group-01-practice-01"
    assert contract_state.last_submission.analysis_status == "PASS"
    assert contract_state.last_submission.judge_status == "AC"
    assert contract_state.last_submission.kind == "submission"
    assert contract_state.last_submission.status_label == "Passed"
    assert contract_state.last_submission.output_text != ""

    state = session.next_practice_level()
    assert state.mode is SessionMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.current_level_id == "group-01-practice-02"
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


def test_game_session_start_group_demo_jumps_to_demo_mode() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()

    state = session.start_group_demo("group-01")
    contract_state = session.current_game_state()

    assert state.mode is SessionMode.DEMO
    assert state.node_id == "group-01-demo"
    assert state.scene_id is None
    assert state.demo_id == "challenge-group-01-demo"
    assert state.current_level_id == "group-01-demo"
    assert contract_state.mode is GameMode.DEMO
    assert contract_state.progress.demo_seen_group_ids == ("group-01",)
    assert contract_state.scene is None
    assert contract_state.demo is not None
    assert contract_state.demo.demo_id == "challenge-group-01-demo"
    assert contract_state.demo.group_id == "group-01"
    assert contract_state.demo.level_id == "group-01-demo"
    assert contract_state.demo.learning_markdown != ""
    assert contract_state.demo.current_level_id == "group-01-demo"
    assert contract_state.practice is None

def test_start_group_demo_replay_stays_in_demo_mode_after_first_clear() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()

    first_demo_state = session.start_group_demo("group-01")
    assert first_demo_state.mode is SessionMode.DEMO
    assert first_demo_state.current_level_id == "group-01-demo"

    after_demo = session.advance()
    assert after_demo.mode is SessionMode.CHALLENGE
    assert after_demo.node_id == "group-01-practice"

    replay_state = session.start_group_demo("group-01")
    assert replay_state.mode is SessionMode.DEMO
    assert replay_state.node_id == "group-01-demo"
    assert replay_state.current_level_id == "group-01-demo"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.DEMO
    assert contract_state.demo is not None
    assert contract_state.demo.current_level_id == "group-01-demo"
    assert contract_state.practice is None
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
    assert contract_state.practice is not None
    assert contract_state.practice.challenge_id == "challenge-group-01-practice"
    assert contract_state.practice.current_level_id == "group-01-practice-01"
    assert contract_state.practice.battery_percent == 0



def test_game_session_can_complete_all_five_groups() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-05-result")

    state = session.advance()
    assert state.node_id == "main-map-entry"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "main-map-entry"
    assert contract_state.available_actions.advance is False
    expected_completed_nodes = ["main-map-entry"]
    for group_number in range(1, 6):
        for slot in ("story", "demo", "practice", "result"):
            expected_completed_nodes.append("group-%02d-%s" % (group_number, slot))
    assert contract_state.progress.completed_node_ids == tuple(expected_completed_nodes)

    expected_cleared_levels = []
    for group_number in range(1, 6):
        for level_number in range(1, 6):
            expected_cleared_levels.append("group-%02d-practice-%02d" % (group_number, level_number))
    assert contract_state.progress.cleared_level_ids == tuple(expected_cleared_levels)

    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group == {
        "group-01": "completed",
        "group-02": "completed",
        "group-03": "completed",
        "group-04": "completed",
        "group-05": "completed",
    }

def test_map_route_marks_only_one_group_current_for_shared_story_scene() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-02-story")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: next(step.status_key for step in group.demo_route if step.step_type == "story") for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] != "current"
    assert status_by_group["group-02"] == "current"
    assert status_by_group["group-03"] != "current"
    assert status_by_group["group-04"] != "current"
    assert status_by_group["group-05"] != "current"

def test_initial_map_marks_group_one_available_not_current() -> None:
    session = build_session()

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "available"
    assert status_by_group["group-02"] == "locked"
    assert status_by_group["group-03"] == "locked"
    assert status_by_group["group-04"] == "locked"
    assert status_by_group["group-05"] == "locked"


def test_group_one_result_returns_to_main_map_entry() -> None:
    session = build_session()

    while True:
        state = session.current_state()
        if state.node_id == "group-01-result":
            break
        if state.mode in {SessionMode.SCENE, SessionMode.DEMO}:
            session.advance()
        else:
            _submit_and_progress(session)

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
    assert status_by_group["group-04"] == "locked"
    assert status_by_group["group-05"] == "locked"

def test_group_three_result_returns_to_main_map_entry_and_unlocks_group_four() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-03-result")

    state = session.advance()
    assert state.node_id == "main-map-entry"

    runtime_state = session.runtime.current_state()
    assert runtime_state is not None
    assert runtime_state.node.node_id == "main-map-entry"
    assert runtime_state.available_next_node_ids == ("group-01-story", "group-02-story", "group-03-story", "group-04-story")

    contract_state = session.current_game_state()
    assert contract_state.available_actions.advance is False
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"
    assert status_by_group["group-02"] == "completed"
    assert status_by_group["group-03"] == "completed"
    assert status_by_group["group-04"] == "available"
    assert status_by_group["group-05"] == "locked"


def test_group_two_becomes_available_after_group_one_completion() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-02-story")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"
    assert status_by_group["group-02"] == "current"
    assert status_by_group["group-03"] == "locked"
    assert status_by_group["group-04"] == "locked"
    assert status_by_group["group-05"] == "locked"


def test_group_story_does_not_unlock_practice_until_demo_node_is_reached() -> None:
    session = build_session()

    while True:
        state = session.current_state()
        if state.node_id == "main-map-entry" and "group-01-result" in set(session.current_game_state().progress.completed_node_ids):
            break
        if state.mode in {SessionMode.SCENE, SessionMode.DEMO}:
            session.advance()
        else:
            _submit_and_progress(session)

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
        if state.mode in {SessionMode.SCENE, SessionMode.DEMO}:
            session.advance()
        else:
            _submit_and_progress(session)

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
    assert contract_state.practice is not None
    assert contract_state.practice.is_review_mode is True


def test_replaying_completed_group_does_not_relock_later_groups() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-03-practice" and state.current_level_id == "group-03-practice-01")

    session.start_group_practice("group-01")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "reviewing"
    assert status_by_group["group-02"] == "completed"
    assert status_by_group["group-03"] == "current"
    assert status_by_group["group-04"] == "locked"
    assert status_by_group["group-05"] == "locked"


def test_all_groups_completed_then_replay_marks_only_replayed_group_reviewing() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-05-result")
    session.advance()

    session.start_group_practice("group-01")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "reviewing"
    assert status_by_group["group-02"] == "completed"
    assert status_by_group["group-03"] == "completed"
    assert status_by_group["group-04"] == "completed"
    assert status_by_group["group-05"] == "completed"


def test_reviewing_practice_advances_to_next_level() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-05-result")
    session.advance()

    state = session.start_group_practice("group-01")
    assert state.current_level_id == "group-01-practice-01"

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.node_id == "group-01-practice"
    assert state.current_level_id == "group-01-practice-01"

    state = session.next_practice_level()
    assert state.mode is SessionMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.current_level_id == "group-01-practice-02"


def test_reviewing_fifth_level_returns_to_map_after_review() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-05-result")
    session.advance()

    session.start_group_practice("group-01")
    for expected_level in ("group-01-practice-01", "group-01-practice-02", "group-01-practice-03", "group-01-practice-04"):
        state, outcome = session.submit_current_level(python_code="print(1)")
        assert outcome.cleared is True
        assert state.current_level_id == expected_level
        state = session.next_practice_level()
        assert state.mode is SessionMode.CHALLENGE

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.mode is SessionMode.CHALLENGE
    assert state.current_level_id == "group-01-practice-05"

    state = session.next_practice_level()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "main-map-entry"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "main-map-entry"


def test_reviewing_practice_fifth_level_returns_to_main_map() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-05-result")
    session.advance()

    session.start_group_practice("group-01")
    for _ in range(4):
        state, outcome = session.submit_current_level(python_code="print(1)")
        assert outcome.cleared is True
        assert state.mode is SessionMode.CHALLENGE
        assert state.current_level_id is not None
        session.next_practice_level()

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.mode is SessionMode.CHALLENGE
    assert state.node_id == "group-01-practice"

    state = session.next_practice_level()
    assert state.mode is SessionMode.SCENE
    assert state.node_id == "main-map-entry"

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "main-map-entry"
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"
    assert status_by_group["group-02"] == "completed"
    assert status_by_group["group-03"] == "completed"
    assert status_by_group["group-04"] == "completed"
    assert status_by_group["group-05"] == "completed"


def test_reviewing_group_does_not_clear_current_from_unfinished_mainline_group() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-02-practice" and state.current_level_id == "group-02-practice-01")

    session.start_group_practice("group-01")

    contract_state = session.current_game_state()
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "reviewing"
    assert status_by_group["group-02"] == "current"
    assert contract_state.practice is not None
    assert contract_state.practice.is_review_mode is True
    assert status_by_group["group-03"] == "locked"
    assert status_by_group["group-04"] == "locked"
    assert status_by_group["group-05"] == "locked"


def test_finishing_review_keeps_current_on_unfinished_mainline_group() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-02-practice" and state.current_level_id == "group-02-practice-01")
    session.start_group_practice("group-01")
    for _ in range(5):
        session.submit_current_level(python_code="print(1)")
        session.next_practice_level()

    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "main-map-entry"
    assert contract_state.map_route is not None
    status_by_group = {group.group_id: group.status_key for group in contract_state.map_route.groups}
    assert status_by_group["group-01"] == "completed"
    assert status_by_group["group-02"] == "current"
    assert status_by_group["group-03"] == "locked"
    assert status_by_group["group-04"] == "locked"
    assert status_by_group["group-05"] == "locked"


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


def test_python_run_records_emitted_output_for_print_empty_string() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()
    session.advance()

    state, outcome = session.run_current_level(python_code='print("")')

    assert state.mode is SessionMode.CHALLENGE
    assert outcome.cleared is False

    contract_state = session.current_game_state()
    assert contract_state.last_submission is not None
    assert contract_state.last_submission.kind == "run_result"
    assert contract_state.last_submission.output_text == ""
    assert contract_state.last_submission.details.get("emitted_output") is True


def test_python_run_with_empty_output_keeps_output_text_empty() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()
    session.advance()

    state, outcome = session.run_current_level(python_code="print("")")

    assert state.mode is SessionMode.CHALLENGE
    assert outcome.cleared is False

    contract_state = session.current_game_state()
    assert contract_state.last_submission is not None
    assert contract_state.last_submission.kind == "run_result"
    assert contract_state.last_submission.output_text == ""


def test_practice_battery_starts_at_zero_and_accumulates_per_submit() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()
    session.advance()

    contract_state = session.current_game_state()
    assert contract_state.practice is not None
    assert contract_state.practice.battery_percent == 0

    expected = (
        ("group-01-practice-01", 20),
        ("group-01-practice-02", 40),
        ("group-01-practice-03", 60),
        ("group-01-practice-04", 80),
        ("group-01-practice-05", 100),
    )
    for level_id, battery_percent in expected:
        state, outcome = session.submit_current_level(python_code="print(1)")
        assert outcome.cleared is True
        assert state.current_level_id == level_id

        contract_state = session.current_game_state()
        assert contract_state.practice is not None
        assert contract_state.practice.battery_percent == battery_percent

        if level_id != "group-01-practice-05":
            state = session.next_practice_level()
            assert state.current_level_id is not None
            contract_state = session.current_game_state()
            assert contract_state.practice is not None
            assert contract_state.practice.battery_percent == battery_percent


def test_practice_battery_does_not_double_count_repeated_successful_submit() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()
    session.advance()

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.current_level_id == "group-01-practice-01"
    contract_state = session.current_game_state()
    assert contract_state.practice is not None
    assert contract_state.practice.battery_percent == 20

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is True
    assert state.current_level_id == "group-01-practice-01"
    contract_state = session.current_game_state()
    assert contract_state.practice is not None
    assert contract_state.practice.battery_percent == 20


def test_practice_battery_failed_submit_does_not_change_battery() -> None:
    levels = load_levels(load_levels_dir())
    levels["group-01-practice-01"].metadata["stub_judge"] = {"status": "WA"}
    app = AppCore(levels, judge=StubJudge())
    assembled = assemble_game_slice(game_content=load_game_content(game_content_dir()), levels=levels)
    session = GameSession.start(app=app, game_slice=assembled, quest_id="quest-main-map")
    session.create_player_profile(name="Test Player", gender="male")
    session.complete_intro()
    session.start_group_story("group-01")
    session.advance()
    session.advance()

    state, outcome = session.submit_current_level(python_code="print(1)")
    assert outcome.cleared is False
    assert state.current_level_id == "group-01-practice-01"
    contract_state = session.current_game_state()
    assert contract_state.practice is not None
    assert contract_state.practice.battery_percent == 0


def test_toolbox_verification_does_not_change_practice_battery() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()
    session.advance()

    session.verify_current_level_with_toolbox(
        python_code="name = input()\nprint(f\"Hello, {name}\")\n",
        block_json={"kind": "toolbox_workspace", "blocks": [{"type": "print_expr", "expr": "Hello"}]},
    )

    contract_state = session.current_game_state()
    assert contract_state.practice is not None
    assert contract_state.practice.battery_percent == 0

    state, outcome = session.submit_current_level(python_code="name = input()\nprint(f\"Hello, {name}\")\n")
    assert outcome.cleared is True
    assert state.current_level_id == "group-01-practice-01"
    contract_state = session.current_game_state()
    assert contract_state.practice is not None
    assert contract_state.practice.battery_percent == 20


def test_practice_battery_resets_after_leaving_incomplete_practice() -> None:
    session = build_session()
    session.start_group_story("group-01")
    session.advance()
    session.advance()

    session.submit_current_level(python_code="print(1)")
    contract_state = session.current_game_state()
    assert contract_state.practice is not None
    assert contract_state.practice.battery_percent == 20

    session.start_group_story("group-01")
    state = session.start_group_practice("group-01")
    assert state.current_level_id == "group-01-practice-02"
    contract_state = session.current_game_state()
    assert contract_state.practice is not None
    assert contract_state.practice.battery_percent == 0


def test_practice_battery_resets_when_restarting_completed_group_practice() -> None:
    session = build_session()

    _progress_until(session, lambda state: state.node_id == "group-01-result")
    contract_state = session.current_game_state()
    assert contract_state.mode is GameMode.SCENE
    assert contract_state.node_id == "group-01-result"

    session.advance()
    state = session.start_group_practice("group-01")
    assert state.current_level_id == "group-01-practice-01"
    contract_state = session.current_game_state()
    assert contract_state.practice is not None
    assert contract_state.practice.battery_percent == 0


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

    contract_state = session.current_game_state()
    assert contract_state.progress.cleared_level_ids == ()
    assert contract_state.progress.toolbox_used_level_ids == ("group-01-practice-01",)
    assert contract_state.last_submission is not None
    assert contract_state.last_submission.verification_only is False
    assert contract_state.last_submission.answer_correct is True
    assert contract_state.last_submission.cleared is False
    assert contract_state.last_submission.kind == "toolbox_run"
    assert contract_state.last_submission.status_label == "Toolbox Run Passed"
    assert contract_state.last_submission.output_text == ""
    assert contract_state.practice is not None
    assert contract_state.practice.toolbox_used is True

    state, outcome = session.submit_current_level(python_code="name = input()\nprint(f\"Hello, {name}\")\n")
    assert outcome.cleared is True
    assert state.current_level_id == "group-01-practice-01"

    state = session.next_practice_level()
    assert state.mode is SessionMode.CHALLENGE
    assert state.node_id == "group-01-practice"
    assert state.current_level_id == "group-01-practice-02"


def build_raw_session() -> GameSession:
    levels = load_levels(load_levels_dir())
    for level in levels.values():
        level.metadata["stub_judge"] = {"status": "AC"}
        level.metadata["placeholder_auto_ac"] = True
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





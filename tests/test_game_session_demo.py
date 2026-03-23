from __future__ import annotations

from block2python.clients.cli.game_session_demo import build_demo_session, run_auto_demo


def test_run_auto_demo_completes_runtime_quest() -> None:
    session = build_demo_session()

    logs = run_auto_demo(session)

    assert session.current_state().mode.value == "COMPLETE"
    assert any("challenge=challenge-group-01-demo" in line for line in logs)
    assert any("challenge=challenge-group-01-practice" in line for line in logs)
    assert any("actions=advance:False submit:True restart_quest:False" in line for line in logs)
    assert any("submit group-01-demo: JudgeStatus.AC" in line for line in logs)
    assert any("submit group-01-practice-05: JudgeStatus.AC" in line for line in logs)

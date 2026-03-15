from __future__ import annotations

from block2python.app.game_session_demo import build_demo_session, run_auto_demo


def test_run_auto_demo_completes_runtime_quest() -> None:
    session = build_demo_session()

    logs = run_auto_demo(session)

    assert session.current_state().mode.value == "COMPLETE"
    assert any("challenge=challenge-demo-basic-io" in line for line in logs)
    assert any("challenge=challenge-practice-basic-io" in line for line in logs)
    assert any("actions=advance:False submit:True restart_quest:False" in line for line in logs)
    assert any("submit demo-basic-io-hello: JudgeStatus.AC" in line for line in logs)
    assert any("submit practice-basic-io-double: JudgeStatus.AC" in line for line in logs)

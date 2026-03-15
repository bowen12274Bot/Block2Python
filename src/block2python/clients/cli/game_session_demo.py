from __future__ import annotations

import argparse
from pathlib import Path
from typing import Callable

from block2python.challenge import AppCore, InMemoryProgress
from block2python.content import assemble_game_slice, load_game_content, load_levels
from block2python.game import GameSession, SessionMode
from block2python.judge import StubJudge


DEFAULT_QUEST_ID = "quest-basic-io-repair"


def build_demo_session(
    *,
    levels_dir: Path | None = None,
    game_content_dir: Path | None = None,
) -> GameSession:
    levels = load_levels(levels_dir or Path("assets/levels"))
    game_content = load_game_content(game_content_dir or Path("assets/game_content"))
    game_slice = assemble_game_slice(game_content=game_content, levels=levels)
    app = AppCore(levels, judge=StubJudge(), progress=InMemoryProgress.empty())
    return GameSession.start(app=app, game_slice=game_slice, quest_id=DEFAULT_QUEST_ID)


def run_auto_demo(
    session: GameSession,
    *,
    code_factory: Callable[[str], str] | None = None,
) -> list[str]:
    logs: list[str] = []
    code_factory = code_factory or _default_code_factory

    while True:
        state = session.current_state()
        logs.extend(_render_state(state))
        if state.mode is SessionMode.COMPLETE:
            break
        if state.mode is SessionMode.SCENE:
            session.advance()
            continue
        if state.current_level_id is None:
            raise RuntimeError("Challenge mode without current_level_id")
        next_state, outcome = session.submit_current_level(python_code=code_factory(state.current_level_id))
        logs.append(f"submit {state.current_level_id}: {outcome.judge.status}")
        logs.append(f"cleared={outcome.cleared}")
        if next_state.mode is SessionMode.CHALLENGE and next_state.current_level_id == state.current_level_id:
            raise RuntimeError(f"Challenge submission did not advance level {state.current_level_id}")

    return logs


def interactive_demo(session: GameSession) -> int:
    print("Block2Python GameSession Demo")
    print("Commands: next, submit, status, quit")
    while True:
        state = session.current_state()
        for line in _render_state(state):
            print(line)
        if state.mode is SessionMode.COMPLETE:
            return 0

        command = input("> ").strip().lower()
        if command in {"quit", "exit"}:
            return 0
        if command == "status":
            continue
        if command == "next":
            session.advance()
            continue
        if command == "submit":
            if state.mode is not SessionMode.CHALLENGE or state.current_level_id is None:
                print("Current state is not a challenge")
                continue
            code = _default_code_factory(state.current_level_id)
            next_state, outcome = session.submit_current_level(python_code=code)
            print(f"submit {state.current_level_id}: {outcome.judge.status} cleared={outcome.cleared}")
            if next_state.mode is SessionMode.CHALLENGE and next_state.current_level_id == state.current_level_id:
                print("Challenge did not advance; submit again or inspect state")
            continue
        print("Unknown command")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run the GameSession demo flow in the terminal.")
    parser.add_argument("--auto", action="store_true", help="Run the whole quest automatically")
    parser.add_argument("--levels-dir", type=Path, default=Path("assets/levels"))
    parser.add_argument("--game-content-dir", type=Path, default=Path("assets/game_content"))
    args = parser.parse_args(argv)

    session = build_demo_session(levels_dir=args.levels_dir, game_content_dir=args.game_content_dir)
    if args.auto:
        for line in run_auto_demo(session):
            print(line)
        return 0
    return interactive_demo(session)


def _render_state(state) -> list[str]:
    lines = [f"mode={state.mode} quest={state.quest_id}"]
    if state.node_id is not None:
        lines.append(f"node={state.node_id} title={state.node_title}")
    if state.scene_id is not None:
        lines.append(f"scene={state.scene_id}")
    if state.challenge_id is not None:
        lines.append(f"challenge={state.challenge_id}")
    if state.current_level_id is not None:
        lines.append(f"level={state.current_level_id} title={state.current_level_title}")
    return lines


def _default_code_factory(_level_id: str) -> str:
    return "print('demo')\n"


if __name__ == "__main__":
    raise SystemExit(main())

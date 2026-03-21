from __future__ import annotations

import argparse
from pathlib import Path
from typing import Callable

from block2python.level_play import AppCore, InMemoryProgress
from block2python.content import assemble_game_slice, load_game_content, load_levels
from block2python.game import GameSession
from block2python.integration.contracts import GameMode, GameState
from block2python.judge import StubJudge


DEFAULT_QUEST_ID = "quest-main-map"


def build_demo_session(
    *,
    levels_dir: Path | None = None,
    game_content_dir: Path | None = None,
    quest_id: str = DEFAULT_QUEST_ID,
) -> GameSession:
    levels = load_levels(levels_dir or Path("assets/levels"))
    game_content = load_game_content(game_content_dir or Path("assets/game_content"))
    game_slice = assemble_game_slice(game_content=game_content, levels=levels)
    app = AppCore(levels, judge=StubJudge(), progress=InMemoryProgress.empty())
    session = GameSession.start(app=app, game_slice=game_slice, quest_id=quest_id)
    session.create_player_profile(name="Demo Player", gender="male")
    session.complete_intro()
    return session


def run_auto_demo(
    session: GameSession,
    *,
    code_factory: Callable[[str], str] | None = None,
) -> list[str]:
    logs: list[str] = []
    code_factory = code_factory or _default_code_factory

    while True:
        state = session.current_game_state()
        logs.extend(_render_state(state))
        if state.mode is GameMode.COMPLETE:
            break
        if state.mode is GameMode.SCENE:
            session.advance()
            continue
        if state.challenge is None or state.challenge.current_level_id is None:
            raise RuntimeError("Challenge mode without current_level_id")
        level_id = state.challenge.current_level_id
        next_state, outcome = session.submit_current_level(python_code=code_factory(level_id))
        logs.append(f"submit {level_id}: {outcome.judge.status}")
        logs.append(f"cleared={outcome.cleared}")
        if next_state.mode.value == "CHALLENGE" and next_state.current_level_id == level_id:
            raise RuntimeError(f"Challenge submission did not advance level {level_id}")

    return logs


def interactive_demo(session: GameSession) -> int:
    print("Block2Python GameSession Demo")
    print("Commands: next, submit, status, quit")
    while True:
        state = session.current_game_state()
        for line in _render_state(state):
            print(line)
        if state.mode is GameMode.COMPLETE:
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
            if state.mode is not GameMode.CHALLENGE or state.challenge is None or state.challenge.current_level_id is None:
                print("Current state is not a challenge")
                continue
            level_id = state.challenge.current_level_id
            code = _default_code_factory(level_id)
            next_state, outcome = session.submit_current_level(python_code=code)
            print(f"submit {level_id}: {outcome.judge.status} cleared={outcome.cleared}")
            if next_state.mode.value == "CHALLENGE" and next_state.current_level_id == level_id:
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


def _render_state(state: GameState) -> list[str]:
    lines = [f"mode={state.mode.value} quest={state.quest_id}"]
    if state.node_id is not None:
        lines.append(f"node={state.node_id} title={state.node_title}")
    if state.scene is not None:
        lines.append(f"scene={state.scene.scene_id} title={state.scene.title}")
    if state.challenge is not None:
        lines.append(f"challenge={state.challenge.challenge_id} type={state.challenge.challenge_type}")
    if state.challenge is not None and state.challenge.current_level_id is not None:
        lines.append(
            f"level={state.challenge.current_level_id} title={state.challenge.current_level_title}"
        )
    lines.append(
        "actions="
        f"advance:{state.available_actions.advance} "
        f"submit:{state.available_actions.submit} "
        f"restart_quest:{state.available_actions.restart_quest}"
    )
    return lines


def _default_code_factory(_level_id: str) -> str:
    return "print('demo')\n"


if __name__ == "__main__":
    raise SystemExit(main())


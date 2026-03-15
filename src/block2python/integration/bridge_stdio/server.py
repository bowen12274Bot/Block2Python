from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import TextIO

from block2python.app.game_session_demo import DEFAULT_QUEST_ID
from block2python.challenge import AppCore, InMemoryProgress, build_judge_from_env
from block2python.content import assemble_game_slice, load_game_content, load_levels
from block2python.game import GameSession
from block2python.integration.contracts import (
    IntegrationContractValidationError,
    deserialize_player_action,
    serialize_game_state,
)
from block2python.integration.service import IntegrationDispatchError, dispatch
from block2python.judge import StubJudge


class BridgeServer:
    def __init__(
        self,
        *,
        levels_dir: Path | None = None,
        game_content_dir: Path | None = None,
        quest_id: str = DEFAULT_QUEST_ID,
        use_stub_judge: bool = False,
    ) -> None:
        self._levels_dir = levels_dir
        self._game_content_dir = game_content_dir
        self._quest_id = quest_id
        self._use_stub_judge = use_stub_judge
        self._session: GameSession | None = None
        self._judge_info: str | None = None

    def handle_request(self, request: object) -> dict[str, object]:
        if not isinstance(request, dict):
            return self._error_response("Request must be a JSON object")

        if request.get("command") == "reset":
            self._session = self._build_session()
            return self._ok_response()

        action_payload = request.get("action")
        if action_payload is None:
            return self._error_response("Request must include action")

        try:
            action = deserialize_player_action(action_payload)
            state = dispatch(self._ensure_session(), action)
        except (IntegrationContractValidationError, IntegrationDispatchError) as exc:
            return self._error_response(str(exc))

        return {
            "ok": True,
            "state": serialize_game_state(state),
            "error": None,
            "debug": self._debug_payload(),
        }

    def serve(self, instream: TextIO, outstream: TextIO) -> int:
        for raw_line in instream:
            line = raw_line.strip()
            if not line:
                continue

            try:
                request = json.loads(line)
            except json.JSONDecodeError as exc:
                response = self._error_response(f"Invalid JSON: {exc.msg}")
            else:
                response = self.handle_request(request)

            outstream.write(json.dumps(response, ensure_ascii=True) + "\n")
            outstream.flush()

        return 0

    def _ensure_session(self) -> GameSession:
        if self._session is None:
            self._session = self._build_session()
        return self._session

    def _build_session(self) -> GameSession:
        levels_dir = self._levels_dir or Path("assets/levels")
        game_content_dir = self._game_content_dir or Path("assets/game_content")

        levels = load_levels(levels_dir)
        game_content = load_game_content(game_content_dir)
        game_slice = assemble_game_slice(game_content=game_content, levels=levels)

        if self._use_stub_judge:
            judge = StubJudge()
            self._judge_info = "judge=StubJudge (forced by BridgeServer.use_stub_judge)"
        else:
            judge, self._judge_info = build_judge_from_env()
        app = AppCore(levels, judge=judge, progress=InMemoryProgress.empty())
        return GameSession.start(
            app=app,
            game_slice=game_slice,
            quest_id=self._quest_id,
        )

    def _ok_response(self) -> dict[str, object]:
        return {
            "ok": True,
            "state": serialize_game_state(self._ensure_session().current_game_state()),
            "error": None,
            "debug": self._debug_payload(),
        }

    @staticmethod
    def _error_response(message: str) -> dict[str, object]:
        return {
            "ok": False,
            "state": None,
            "error": message,
            "debug": None,
        }

    def _debug_payload(self) -> dict[str, object]:
        return {
            "judge_info": self._judge_info,
            "use_stub_judge": self._use_stub_judge,
        }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run the Block2Python stdio bridge server.")
    parser.add_argument("--levels-dir", type=Path, default=Path("assets/levels"))
    parser.add_argument("--game-content-dir", type=Path, default=Path("assets/game_content"))
    parser.add_argument("--quest-id", default=DEFAULT_QUEST_ID)
    args = parser.parse_args(argv)

    server = BridgeServer(
        levels_dir=args.levels_dir,
        game_content_dir=args.game_content_dir,
        quest_id=args.quest_id,
    )
    return server.serve(sys.stdin, sys.stdout)


if __name__ == "__main__":
    raise SystemExit(main())
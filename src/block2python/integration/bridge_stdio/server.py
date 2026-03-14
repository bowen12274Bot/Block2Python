from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import TextIO

from block2python.app.game_session_demo import DEFAULT_QUEST_ID, build_demo_session
from block2python.game import GameSession
from block2python.integration.contracts import (
    IntegrationContractValidationError,
    deserialize_player_action,
    serialize_game_state,
)
from block2python.integration.service import IntegrationDispatchError, dispatch


class BridgeServer:
    def __init__(
        self,
        *,
        levels_dir: Path | None = None,
        game_content_dir: Path | None = None,
        quest_id: str = DEFAULT_QUEST_ID,
    ) -> None:
        self._levels_dir = levels_dir
        self._game_content_dir = game_content_dir
        self._quest_id = quest_id
        self._session: GameSession | None = None

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
        return build_demo_session(
            levels_dir=self._levels_dir,
            game_content_dir=self._game_content_dir,
            quest_id=self._quest_id,
        )

    def _ok_response(self) -> dict[str, object]:
        return {
            "ok": True,
            "state": serialize_game_state(self._ensure_session().current_game_state()),
            "error": None,
        }

    @staticmethod
    def _error_response(message: str) -> dict[str, object]:
        return {
            "ok": False,
            "state": None,
            "error": message,
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

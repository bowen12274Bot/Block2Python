from __future__ import annotations

import argparse
import asyncio
import json
import sys
from collections.abc import Mapping
from pathlib import Path
from typing import TextIO

from block2python.ai import (
    LocalTemplateSelector,
    StubTutorProvider,
    TeachingSkillLoader,
    TemplateTutorProvider,
    TutorContextBuilder,
    TutorPolicy,
    TutorService,
)
from block2python.clients.cli.game_session_demo import DEFAULT_QUEST_ID
from block2python.contracts import Submission
from block2python.level_play import AppCore, InMemoryProgress, build_judge_from_env
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
        teaching_skills_dir: Path | None = None,
        quest_id: str = DEFAULT_QUEST_ID,
        use_stub_judge: bool = False,
    ) -> None:
        self._levels_dir = levels_dir
        self._game_content_dir = game_content_dir
        self._teaching_skills_dir = teaching_skills_dir
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

        if request.get("command") == "tutor_reply":
            payload = request.get("payload", {})
            if not isinstance(payload, dict):
                return self._error_response("tutor_reply payload must be an object")

            try:
                tutor_payload = self._handle_tutor_reply(payload)
            except ValueError as exc:
                return self._error_response(str(exc))

            return self._ok_response(tutor=tutor_payload)

        action_payload = request.get("action")
        if action_payload is None:
            return self._error_response("Request must include action")

        try:
            action = deserialize_player_action(action_payload)
            state = dispatch(self._ensure_session(), action)
        except (IntegrationContractValidationError, IntegrationDispatchError) as exc:
            return self._error_response(str(exc))

        return self._ok_response(state=state)

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

    def _ok_response(self, *, state=None, tutor: dict[str, object] | None = None) -> dict[str, object]:
        active_state = state
        if active_state is None:
            active_state = self._ensure_session().current_game_state()

        return {
            "ok": True,
            "state": serialize_game_state(active_state),
            "tutor": tutor,
            "error": None,
            "debug": self._debug_payload(),
        }

    @staticmethod
    def _error_response(message: str) -> dict[str, object]:
        return {
            "ok": False,
            "state": None,
            "tutor": None,
            "error": message,
            "debug": None,
        }

    def _debug_payload(self) -> dict[str, object]:
        return {
            "judge_info": self._judge_info,
            "use_stub_judge": self._use_stub_judge,
        }

    def _handle_tutor_reply(self, payload: Mapping[str, object]) -> dict[str, object]:
        question_raw = payload.get("question")
        if not isinstance(question_raw, str) or not question_raw.strip():
            raise ValueError("tutor_reply requires payload.question")
        question = question_raw.strip()

        provider_raw = payload.get("provider", "template")
        if not isinstance(provider_raw, str) or not provider_raw.strip():
            raise ValueError("tutor_reply payload.provider must be a string")
        provider_name = provider_raw.strip().lower()

        level_id_raw = payload.get("level_id")
        level_id: str | None
        if level_id_raw is None:
            level_id = self._ensure_session().current_state().current_level_id
        elif isinstance(level_id_raw, str) and level_id_raw.strip():
            level_id = level_id_raw.strip()
        else:
            raise ValueError("tutor_reply payload.level_id must be a string when provided")

        if not level_id:
            raise ValueError("tutor_reply requires payload.level_id when no active challenge level")

        python_code_raw = payload.get("python_code", "")
        if not isinstance(python_code_raw, str):
            raise ValueError("tutor_reply payload.python_code must be a string")
        python_code = python_code_raw

        block_json_raw = payload.get("block_json")
        if block_json_raw is not None and not isinstance(block_json_raw, dict):
            raise ValueError("tutor_reply payload.block_json must be a dict or null")

        conversation_id_raw = payload.get("conversation_id")
        if conversation_id_raw is not None and not isinstance(conversation_id_raw, str):
            raise ValueError("tutor_reply payload.conversation_id must be a string")
        conversation_id = conversation_id_raw

        conversation_history_raw = payload.get("conversation_history")
        if conversation_history_raw is not None and not isinstance(conversation_history_raw, list):
            raise ValueError("tutor_reply payload.conversation_history must be an array")

        history_summary_raw = payload.get("history_summary")
        if history_summary_raw is not None and not isinstance(history_summary_raw, str):
            raise ValueError("tutor_reply payload.history_summary must be a string")

        session = self._ensure_session()
        level = session.app.get_level(level_id)
        if level is None:
            raise ValueError(f"Unknown level_id: {level_id}")

        submission = Submission(level_id=level_id, python_code=python_code, block_json=block_json_raw)
        outcome = session.app.verify(submission)

        tutor_service = self._build_tutor_service(provider_name)
        tutor_response = asyncio.run(
            tutor_service.reply(
                level=level,
                submission=submission,
                question=question,
                analysis_result=outcome.analysis,
                judge_result=outcome.judge,
                conversation_id=conversation_id,
                conversation_history=conversation_history_raw,
                history_summary=history_summary_raw,
            )
        )

        return {
            "reply_type": tutor_response.reply_type,
            "content": tutor_response.content,
            "metadata": dict(tutor_response.metadata),
        }

    def _build_tutor_service(self, provider_name: str) -> TutorService:
        skills_dir = self._teaching_skills_dir or Path("assets/teaching_skills")
        skill_loader = TeachingSkillLoader(skills_dir=skills_dir)
        context_builder = TutorContextBuilder(skill_loader=skill_loader)
        policy = TutorPolicy()

        if provider_name == "template":
            provider = TemplateTutorProvider()
        elif provider_name == "stub":
            provider = StubTutorProvider()
        elif provider_name == "local":
            provider = LocalTemplateSelector(template_provider=TemplateTutorProvider())
        else:
            raise ValueError(f"Unsupported tutor provider: {provider_name}")

        return TutorService(
            skill_loader=skill_loader,
            context_builder=context_builder,
            policy=policy,
            provider=provider,
        )


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

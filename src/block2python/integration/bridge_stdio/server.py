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
    OpenAICompatibleProvider,
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
    deserialize_tutor_reply_request,
    serialize_game_state,
    serialize_tutor_reply_payload,
    TutorReplyPayload,
    TutorReplyRequest,
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
            try:
                tutor_request = deserialize_tutor_reply_request(request.get("payload", {}))
                tutor_payload = self._handle_tutor_reply(tutor_request)
            except (IntegrationContractValidationError, ValueError) as exc:
                return self._error_response(str(exc))

            return self._ok_response(tutor=serialize_tutor_reply_payload(tutor_payload))

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

    def _handle_tutor_reply(self, request: TutorReplyRequest) -> TutorReplyPayload:
        provider_name = request.provider

        level_id = request.level_id
        if level_id is None:
            level_id = self._ensure_session().current_state().current_level_id

        if not level_id:
            raise ValueError("tutor_reply requires payload.level_id when no active challenge level")

        session = self._ensure_session()
        level = session.app.get_level(level_id)
        if level is None:
            raise ValueError(f"Unknown level_id: {level_id}")

        submission = Submission(level_id=level_id, python_code=request.python_code, block_json=request.block_json)
        outcome = session.app.verify(submission)

        tutor_service = self._build_tutor_service(provider_name, request.provider_options)
        tutor_response = asyncio.run(
            tutor_service.reply(
                level=level,
                submission=submission,
                question=request.question,
                analysis_result=outcome.analysis,
                judge_result=outcome.judge,
                conversation_id=request.conversation_id,
                conversation_history=list(request.conversation_history),
                history_summary=request.history_summary,
                submission_history=list(request.recent_feedback),
            )
        )

        return TutorReplyPayload(
            reply_type=tutor_response.reply_type,
            content=tutor_response.content,
            metadata=dict(tutor_response.metadata),
        )

    def _build_tutor_service(
        self,
        provider_name: str,
        provider_options: Mapping[str, object] | None = None,
    ) -> TutorService:
        skills_dir = self._teaching_skills_dir or Path("assets/teaching_skills")
        skill_loader = TeachingSkillLoader(skills_dir=skills_dir)
        context_builder = TutorContextBuilder(skill_loader=skill_loader)
        policy = TutorPolicy()
        options = dict(provider_options or {})

        if provider_name == "template":
            provider = TemplateTutorProvider()
        elif provider_name == "stub":
            provider = StubTutorProvider()
        elif provider_name == "local":
            provider = LocalTemplateSelector(template_provider=TemplateTutorProvider())
        elif provider_name == "openai_compatible":
            endpoint_url = _required_non_empty_str(options.get("endpoint_url"), field_name="provider_options.endpoint_url")
            model = _required_non_empty_str(options.get("model"), field_name="provider_options.model")
            api_key = _required_non_empty_str(options.get("api_key"), field_name="provider_options.api_key")
            timeout_sec = _parse_timeout_sec(options.get("timeout_sec"), default=30.0)
            system_prompt_raw = options.get("system_prompt")
            if system_prompt_raw is not None and not isinstance(system_prompt_raw, str):
                raise ValueError("provider_options.system_prompt must be a string")

            provider = OpenAICompatibleProvider(
                endpoint_url=endpoint_url,
                model=model,
                api_key=api_key,
                timeout_sec=timeout_sec,
                system_prompt=system_prompt_raw,
            )
        else:
            raise ValueError(f"Unsupported tutor provider: {provider_name}")

        return TutorService(
            skill_loader=skill_loader,
            context_builder=context_builder,
            policy=policy,
            provider=provider,
        )


def _required_non_empty_str(value: object, *, field_name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{field_name} must be a non-empty string")
    return value.strip()


def _parse_timeout_sec(value: object, *, default: float) -> float:
    if value is None:
        return default
    if isinstance(value, bool):
        raise ValueError("provider_options.timeout_sec must be a positive number")
    try:
        parsed = float(value)
    except (TypeError, ValueError) as exc:
        raise ValueError("provider_options.timeout_sec must be a positive number") from exc
    if parsed <= 0:
        raise ValueError("provider_options.timeout_sec must be a positive number")
    return parsed


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

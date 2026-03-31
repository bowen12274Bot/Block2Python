from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
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


CANONICAL_TUTOR_PROVIDERS: tuple[str, ...] = ("stub", "temple", "api_skill")
TUTOR_PROVIDER_ALIASES: dict[str, str] = {
    "stub": "stub",
    "temple": "temple",
    "template": "temple",
    "local": "temple",
    "api_skill": "api_skill",
    "api+skill": "api_skill",
    "api-skill": "api_skill",
    "openai_compatible": "api_skill",
}


class BridgeServer:
    def __init__(
        self,
        *,
        levels_dir: Path | None = None,
        game_content_dir: Path | None = None,
        teaching_skills_dir: Path | None = None,
        quest_id: str = DEFAULT_QUEST_ID,
        use_stub_judge: bool = False,
        log_file: Path | None = None,
        thinking_log_file: Path | None = None,
    ) -> None:
        self._levels_dir = levels_dir
        self._game_content_dir = game_content_dir
        self._teaching_skills_dir = teaching_skills_dir
        self._quest_id = quest_id
        self._use_stub_judge = use_stub_judge
        self._logger = _configure_bridge_logger(log_file, thinking_log_file)
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
                try:
                    response = self.handle_request(request)
                except Exception:  # pragma: no cover - hard to predict every runtime fault
                    self._logger.exception("Unhandled bridge request error")
                    response = self._error_response("Bridge internal error. See bridge log for details.")

            try:
                outstream.write(json.dumps(response, ensure_ascii=True) + "\n")
                outstream.flush()
            except Exception:
                self._logger.exception("Failed to write bridge response")
                return 1

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
        requested_provider = request.provider
        provider_name = _normalize_tutor_provider(requested_provider)
        _log_tutor_trace(
            self._logger,
            "bridge_tutor_request_received",
            provider=provider_name,
            requested_provider=requested_provider,
            requested_level_id=request.level_id,
            question_chars=len(request.question.strip()),
            code_chars=len(request.python_code),
            has_block_json=bool(request.block_json),
            conversation_id=bool(request.conversation_id),
            history_turns=len(request.conversation_history),
            recent_feedback_count=len(request.recent_feedback),
            provider_options=_summarize_provider_options(request.provider_options),
        )

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
        _log_tutor_trace(
            self._logger,
            "bridge_tutor_submission_verified",
            level_id=level_id,
            analysis_status=getattr(outcome.analysis, "status", "UNKNOWN"),
            judge_status=getattr(outcome.judge, "status", "UNKNOWN"),
        )

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
        _log_tutor_trace(
            self._logger,
            "bridge_tutor_response_ready",
            level_id=level_id,
            provider=provider_name,
            reply_type=tutor_response.reply_type,
            content_chars=len(tutor_response.content),
            metadata_keys=sorted(tutor_response.metadata.keys()),
            provider_metadata=_summarize_response_metadata(tutor_response.metadata),
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
        provider_name = _normalize_tutor_provider(provider_name)
        skills_dir = self._teaching_skills_dir or Path("assets/teaching_skills")
        skill_loader = TeachingSkillLoader(skills_dir=skills_dir)
        context_builder = TutorContextBuilder(skill_loader=skill_loader)
        policy = TutorPolicy()
        options = dict(provider_options or {})

        if provider_name == "stub":
            provider = StubTutorProvider()
        elif provider_name == "temple":
            endpoint_url = _optional_str(options.get("endpoint_url"), default="")
            model = _optional_str(options.get("model"), default="qwen3.5:0.8b")
            api_key = _optional_str(options.get("api_key"), default="")
            timeout_sec = _parse_timeout_sec(options.get("timeout_sec"), default=20.0)
            system_prompt_raw = options.get("system_prompt")
            if system_prompt_raw is not None and not isinstance(system_prompt_raw, str):
                raise ValueError("provider_options.system_prompt must be a string")

            provider = LocalTemplateSelector(
                template_provider=TemplateTutorProvider(),
                model_name=model,
                endpoint_url=endpoint_url,
                api_key=api_key,
                timeout_sec=timeout_sec,
                system_prompt=system_prompt_raw,
            )
        elif provider_name == "api_skill":
            endpoint_url = _required_non_empty_str(options.get("endpoint_url"), field_name="provider_options.endpoint_url")
            model = _required_non_empty_str(options.get("model"), field_name="provider_options.model")
            api_key = _optional_str(options.get("api_key"), default="")
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


def _optional_str(value: object, *, default: str) -> str:
    if value is None:
        return default
    if not isinstance(value, str):
        raise ValueError("provider_options fields must be strings")
    text = value.strip()
    if text == "":
        return default
    return text


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


def _default_log_file() -> Path | None:
    raw = os.environ.get("BLOCK2PYTHON_BRIDGE_LOG_PATH", "").strip()
    if raw == "":
        return None
    return Path(raw)


def _default_thinking_log_file() -> Path | None:
    raw = os.environ.get("BLOCK2PYTHON_TUTOR_THINKING_LOG_PATH", "").strip()
    if raw == "-":
        return None
    if raw != "":
        return Path(raw)
    return None


def _configure_bridge_logger(log_file: Path | None, thinking_log_file: Path | None) -> logging.Logger:
    parent_logger = logging.getLogger("block2python")
    logger = logging.getLogger("block2python.integration.bridge_stdio.server")
    thinking_target = thinking_log_file if thinking_log_file is not None else _default_thinking_log_file()
    _configure_tutor_thinking_logger(thinking_target)

    parent_logger.setLevel(logging.INFO)
    parent_logger.propagate = False
    target = log_file if log_file is not None else _default_log_file()
    has_file_handler = any(isinstance(handler, logging.FileHandler) for handler in parent_logger.handlers)

    if target is not None and not has_file_handler:
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            file_handler = logging.FileHandler(target, encoding="utf-8")
            file_handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
            parent_logger.addHandler(file_handler)
            logger.info("Bridge log started")
        except OSError:
            # Logging must never prevent the bridge process from starting.
            pass

    setattr(parent_logger, "_block2python_configured", True)
    return logger


def _configure_tutor_thinking_logger(log_file: Path | None) -> logging.Logger:
    logger = logging.getLogger("block2python.tutor_thinking")
    logger.setLevel(logging.INFO)
    logger.propagate = False
    target = log_file
    has_file_handler = any(isinstance(handler, logging.FileHandler) for handler in logger.handlers)
    if target is None:
        setattr(logger, "_block2python_configured", True)
        return logger

    if not has_file_handler:
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            file_handler = logging.FileHandler(target, encoding="utf-8")
            file_handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
            logger.addHandler(file_handler)
            logger.info("Tutor thinking log started")
        except OSError:
            # Thinking trace logging is optional and must never break the bridge.
            pass

    setattr(logger, "_block2python_configured", True)
    return logger


def _summarize_provider_options(options: Mapping[str, object]) -> dict[str, object]:
    summary: dict[str, object] = {}
    endpoint = options.get("endpoint_url")
    model = options.get("model")
    timeout = options.get("timeout_sec")

    if isinstance(endpoint, str) and endpoint.strip():
        summary["endpoint_url"] = endpoint.strip()
    if isinstance(model, str) and model.strip():
        summary["model"] = model.strip()
    if timeout is not None:
        summary["timeout_sec"] = timeout
    summary["has_api_key"] = bool(str(options.get("api_key", "")).strip())
    summary["has_system_prompt"] = bool(str(options.get("system_prompt", "")).strip())
    return summary


def _summarize_response_metadata(metadata: Mapping[str, object]) -> dict[str, object]:
    summary: dict[str, object] = {}
    for key in (
        "provider",
        "reply_type",
        "template_id",
        "template_variant",
        "reason_code",
        "selected_reply_type",
        "selector_source",
        "selector_model",
        "selector_reason",
        "model",
        "error_code",
        "attempt",
        "history_compressed",
        "history_token_estimate",
    ):
        if key in metadata:
            summary[key] = metadata[key]

    usage = metadata.get("usage")
    if isinstance(usage, Mapping):
        summary["usage"] = {
            "prompt_tokens": usage.get("prompt_tokens"),
            "completion_tokens": usage.get("completion_tokens"),
            "total_tokens": usage.get("total_tokens"),
        }
    return summary


def _normalize_tutor_provider(provider_name: str) -> str:
    normalized = provider_name.strip().lower()
    mapped = TUTOR_PROVIDER_ALIASES.get(normalized)
    if mapped is None:
        supported = ", ".join(CANONICAL_TUTOR_PROVIDERS)
        raise ValueError(f"Unsupported tutor provider: {provider_name}. Supported: {supported}")
    return mapped


def _humanize_trace_fields(fields: Mapping[str, object]) -> str:
    parts: list[str] = []
    for key in sorted(fields.keys()):
        parts.append(f"{key}={_humanize_trace_value(fields[key])}")
    return "; ".join(parts)


def _humanize_trace_value(value: object) -> str:
    if isinstance(value, Mapping):
        inner = ", ".join(f"{k}={_humanize_trace_value(v)}" for k, v in sorted(value.items(), key=lambda item: str(item[0])))
        return "{" + inner + "}"
    if isinstance(value, (list, tuple, set)):
        return "[" + ", ".join(_humanize_trace_value(item) for item in value) + "]"
    text = str(value)
    if len(text) > 160:
        return text[:157] + "..."
    return text


def _log_tutor_trace(logger: logging.Logger, event: str, **fields: object) -> None:
    payload = {"event": event, **fields}
    logger.info("TUTOR_TRACE %s", json.dumps(payload, ensure_ascii=False, default=str, sort_keys=True))
    logger.info("TUTOR_TRACE_HUMAN %s | %s", event, _humanize_trace_fields(fields))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run the Block2Python stdio bridge server.")
    parser.add_argument("--levels-dir", type=Path, default=Path("assets/levels"))
    parser.add_argument("--game-content-dir", type=Path, default=Path("assets/game_content"))
    parser.add_argument("--teaching-skills-dir", type=Path, default=Path("assets/teaching_skills"))
    parser.add_argument("--quest-id", default=DEFAULT_QUEST_ID)
    parser.add_argument("--log-file", type=Path, default=_default_log_file())
    parser.add_argument("--thinking-log-file", type=Path, default=Path("log/tutor_thinking.log"))
    args = parser.parse_args(argv)

    server = BridgeServer(
        levels_dir=args.levels_dir,
        game_content_dir=args.game_content_dir,
        teaching_skills_dir=args.teaching_skills_dir,
        quest_id=args.quest_id,
        log_file=args.log_file,
        thinking_log_file=args.thinking_log_file,
    )
    return server.serve(sys.stdin, sys.stdout)


if __name__ == "__main__":
    raise SystemExit(main())

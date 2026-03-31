from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import time
from collections.abc import Mapping, Sequence

from block2python.contracts import AnalysisResult, JudgeResult, LevelSpec, Submission

from .context_builder import TutorContextBuilder
from .history import ConversationHistoryCompressor
from .models import ConversationTurn, TeachingSkill, TutorContext, TutorReplyType, TutorResponse
from .policy import TutorPolicy
from .providers.base import TutorProvider
from .teaching_skill_loader import TeachingSkillLoader

logger = logging.getLogger(__name__)


class TutorService:
    TOTAL_TIMEOUT_SEC = 60.0
    ATTEMPT_TIMEOUT_SEC = 30.0
    MAX_RETRY = 3
    LOCAL_SELECTOR_MAX_RETRY = 1
    LOCAL_SELECTOR_ATTEMPT_TIMEOUT_SEC = 12.0
    API_SKILL_ATTEMPT_TIMEOUT_SEC = 60.0

    def __init__(
        self,
        *,
        skill_loader: TeachingSkillLoader,
        context_builder: TutorContextBuilder,
        policy: TutorPolicy,
        provider: TutorProvider,
        history_compressor: ConversationHistoryCompressor | None = None,
    ) -> None:
        self.skill_loader = skill_loader
        self.context_builder = context_builder
        self.policy = policy
        self.provider = provider
        self.history_compressor = history_compressor or ConversationHistoryCompressor()

    async def reply(
        self,
        *,
        level: LevelSpec,
        submission: Submission,
        question: str,
        analysis_result: AnalysisResult | None = None,
        judge_result: JudgeResult | None = None,
        conversation_id: str | None = None,
        conversation_history: Sequence[ConversationTurn | Mapping[str, object]] | None = None,
        history_summary: str | None = None,
        submission_history: Sequence[str] | None = None,
    ) -> TutorResponse:
        provider_name = self.provider.__class__.__name__
        request_id = _build_request_id(
            level_id=level.level_id,
            question=question,
            conversation_id=conversation_id,
        )

        _log_tutor_trace(
            "service_start",
            request_id=request_id,
            level_id=level.level_id,
            provider=provider_name,
            question_preview=_preview(question),
            question_chars=len(question.strip()),
            code_chars=len(submission.python_code),
            has_block_json=bool(submission.block_json),
            conversation_id=conversation_id,
            history_turns=len(conversation_history or ()),
            submission_feedback_count=len(submission_history or ()),
            requested_skill_count=len(level.teaching_skill_ids),
        )

        try:
            skills, missing_skill_ids = self._load_skills_safe(level.teaching_skill_ids)
            _log_tutor_trace(
                "skills_loaded",
                request_id=request_id,
                loaded_skill_count=len(skills),
                missing_skill_ids=list(missing_skill_ids),
            )

            normalized_history = _normalize_history(conversation_history)
            compressed_history = self.history_compressor.compress(normalized_history, history_summary)
            _log_tutor_trace(
                "history_prepared",
                request_id=request_id,
                normalized_turns=len(normalized_history),
                compressed_turns=len(compressed_history.history),
                compressed=compressed_history.compressed,
                token_estimate=compressed_history.token_estimate,
            )

            context = self.context_builder.build(
                level=level,
                submission=submission,
                analysis_result=analysis_result,
                judge_result=judge_result,
                question=question,
                skills=skills,
                conversation_id=conversation_id,
                conversation_history=compressed_history.history,
                history_summary=compressed_history.summary,
                submission_history=submission_history,
            )

            reply_type = self.policy.determine_reply_type(context, question)
            _log_tutor_trace(
                "policy_decision",
                request_id=request_id,
                reply_type=reply_type,
                analysis_status=context.analysis_status,
                judge_status=context.judge_status,
                has_failed_case=bool(context.failed_cases_summary),
            )
            if reply_type in {"scope_refusal", "solution_refusal"}:
                refusal_response = self._handle_refusal(context, reply_type)
                _log_tutor_trace(
                    "policy_refusal",
                    request_id=request_id,
                    reply_type=reply_type,
                )
                return self._decorate_response(
                    refusal_response,
                    missing_skill_ids=missing_skill_ids,
                    history_compressed=compressed_history.compressed,
                    history_token_estimate=compressed_history.token_estimate,
                    attempt=0,
                )

            started_at = time.monotonic()
            last_error: Exception | None = None
            max_retry = self._resolve_max_retry(provider_name)
            attempt_timeout_cap = self._resolve_attempt_timeout_cap(provider_name)
            for attempt in range(1, max_retry + 1):
                elapsed = time.monotonic() - started_at
                remaining = self.TOTAL_TIMEOUT_SEC - elapsed
                if remaining <= 0:
                    break

                attempt_timeout = min(remaining, attempt_timeout_cap)
                _log_tutor_trace(
                    "provider_attempt_start",
                    request_id=request_id,
                    provider=provider_name,
                    attempt=attempt,
                    attempt_timeout_sec=round(attempt_timeout, 3),
                    remaining_budget_sec=round(remaining, 3),
                    target_reply_type=reply_type,
                )
                try:
                    response = await asyncio.wait_for(
                        self.provider.reply(context, reply_type),
                        timeout=attempt_timeout,
                    )
                    if not response.content.strip():
                        raise RuntimeError("Tutor provider returned empty content")
                    _log_tutor_trace(
                        "provider_attempt_success",
                        request_id=request_id,
                        provider=provider_name,
                        attempt=attempt,
                        reply_type=response.reply_type,
                        content_chars=len(response.content),
                        metadata=_summarize_metadata(response.metadata),
                    )
                    return self._decorate_response(
                        response,
                        missing_skill_ids=missing_skill_ids,
                        history_compressed=compressed_history.compressed,
                        history_token_estimate=compressed_history.token_estimate,
                        attempt=attempt,
                    )
                except Exception as exc:  # noqa: BLE001
                    last_error = exc
                    logger.warning(
                        "Tutor provider failed (attempt=%s/%s) for level %s: %s",
                        attempt,
                        max_retry,
                        level.level_id,
                        exc,
                    )
                    _log_tutor_trace(
                        "provider_attempt_failed",
                        request_id=request_id,
                        provider=provider_name,
                        attempt=attempt,
                        error_type=type(exc).__name__,
                        error=str(exc),
                    )

            _log_tutor_trace(
                "provider_fallback_default",
                request_id=request_id,
                provider=provider_name,
                attempts=max_retry,
                last_error=str(last_error) if last_error is not None else "timeout",
            )
            return self._decorate_response(
                TutorResponse(
                    reply_type="scope_refusal",
                    content=(
                        "Tutor is temporarily unavailable. "
                        "Please re-check the prompt, input/output format, and your variable usage first."
                    ),
                    metadata={
                        "error": str(last_error) if last_error is not None else "timeout",
                        "error_code": "provider_unavailable",
                        "fallback": "friendly_default",
                    },
                ),
                missing_skill_ids=missing_skill_ids,
                history_compressed=compressed_history.compressed,
                history_token_estimate=compressed_history.token_estimate,
                attempt=max_retry,
            )

        except Exception as exc:  # noqa: BLE001
            logger.error("Unexpected error in tutor reply: %s", exc, exc_info=True)
            _log_tutor_trace(
                "service_internal_error",
                request_id=request_id,
                provider=provider_name,
                error_type=type(exc).__name__,
                error=str(exc),
            )
            return TutorResponse(
                reply_type="scope_refusal",
                content="Tutor encountered an internal error and cannot reply right now.",
                metadata={"error": str(exc), "error_code": "internal_error"},
            )

    def _load_skills_safe(self, skill_ids: Sequence[str]) -> tuple[tuple[TeachingSkill, ...], tuple[str, ...]]:
        loaded: list[TeachingSkill] = []
        missing: list[str] = []

        for skill_id in skill_ids:
            normalized_id = skill_id.strip()
            if not normalized_id:
                continue
            try:
                loaded.append(self.skill_loader.load_skill(normalized_id))
            except FileNotFoundError:
                missing.append(normalized_id)
                logger.warning("Teaching skill '%s' not found; skipping", normalized_id)
            except Exception as exc:  # noqa: BLE001
                logger.warning("Error loading skill '%s': %s", normalized_id, exc)

        return tuple(loaded), tuple(missing)

    def _handle_refusal(self, context: TutorContext, reply_type: TutorReplyType) -> TutorResponse:
        if reply_type == "scope_refusal":
            if context.forbidden_concepts:
                forbidden = ", ".join(context.forbidden_concepts)
                content = f"This request is out of scope for the current level. Avoid: {forbidden}."
            else:
                content = "This request is outside the current level scope."
        else:
            if context.hint_ladder:
                content = f"I cannot provide a full solution. Try this hint: {context.hint_ladder[0]}"
            else:
                content = "I cannot provide a full solution, but I can provide hints step by step."

        return TutorResponse(reply_type=reply_type, content=content, metadata={"provider": "policy"})

    @classmethod
    def _resolve_max_retry(cls, provider_name: str) -> int:
        if provider_name == "LocalTemplateSelector":
            return cls.LOCAL_SELECTOR_MAX_RETRY
        return cls.MAX_RETRY

    @classmethod
    def _resolve_attempt_timeout_cap(cls, provider_name: str) -> float:
        if provider_name == "LocalTemplateSelector":
            return cls.LOCAL_SELECTOR_ATTEMPT_TIMEOUT_SEC
        if provider_name == "OpenAICompatibleProvider":
            return cls.API_SKILL_ATTEMPT_TIMEOUT_SEC
        return cls.ATTEMPT_TIMEOUT_SEC

    @staticmethod
    def _decorate_response(
        response: TutorResponse,
        *,
        missing_skill_ids: Sequence[str],
        history_compressed: bool,
        history_token_estimate: int,
        attempt: int,
    ) -> TutorResponse:
        metadata = dict(response.metadata)
        metadata.setdefault("reply_type", response.reply_type)
        metadata.setdefault("attempt", attempt)
        metadata["history_compressed"] = history_compressed
        metadata["history_token_estimate"] = history_token_estimate
        if missing_skill_ids:
            metadata["missing_skill_ids"] = list(missing_skill_ids)

        return TutorResponse(reply_type=response.reply_type, content=response.content, metadata=metadata)


def _normalize_history(
    conversation_history: Sequence[ConversationTurn | Mapping[str, object]] | None,
) -> tuple[ConversationTurn, ...]:
    if not conversation_history:
        return ()

    normalized: list[ConversationTurn] = []
    for turn in conversation_history:
        if isinstance(turn, ConversationTurn):
            if turn.content.strip():
                normalized.append(turn)
            continue

        if not isinstance(turn, Mapping):
            continue

        role_raw = turn.get("role", "user")
        role = str(role_raw).strip().lower() if role_raw is not None else "user"
        if role not in {"user", "assistant", "system"}:
            role = "user"

        content_raw = turn.get("content", "")
        content = str(content_raw).strip() if content_raw is not None else ""
        if not content:
            continue

        normalized.append(ConversationTurn(role=role, content=content))

    return tuple(normalized)


def _build_request_id(*, level_id: str, question: str, conversation_id: str | None) -> str:
    basis = f"{level_id}|{conversation_id or ''}|{question.strip()}|{time.time_ns()}"
    return hashlib.sha1(basis.encode("utf-8"), usedforsecurity=False).hexdigest()[:12]


def _preview(text: str, *, limit: int = 120) -> str:
    normalized = " ".join(text.strip().split())
    if len(normalized) <= limit:
        return normalized
    return normalized[: limit - 3] + "..."


def _summarize_metadata(metadata: Mapping[str, object]) -> dict[str, object]:
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
        "history_compressed",
        "history_token_estimate",
        "attempt",
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


def _log_tutor_trace(event: str, **fields: object) -> None:
    payload = {"event": event, **fields}
    logger.info("TUTOR_TRACE %s", json.dumps(payload, ensure_ascii=False, default=str, sort_keys=True))
    logger.info("TUTOR_TRACE_HUMAN %s | %s", event, _humanize_trace_fields(fields))


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

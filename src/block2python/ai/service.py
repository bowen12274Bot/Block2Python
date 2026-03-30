from __future__ import annotations

import asyncio
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
        try:
            skills, missing_skill_ids = self._load_skills_safe(level.teaching_skill_ids)

            normalized_history = _normalize_history(conversation_history)
            compressed_history = self.history_compressor.compress(normalized_history, history_summary)

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
            if reply_type in {"scope_refusal", "solution_refusal"}:
                refusal_response = self._handle_refusal(context, reply_type)
                return self._decorate_response(
                    refusal_response,
                    missing_skill_ids=missing_skill_ids,
                    history_compressed=compressed_history.compressed,
                    history_token_estimate=compressed_history.token_estimate,
                    attempt=0,
                )

            started_at = time.monotonic()
            last_error: Exception | None = None
            for attempt in range(1, self.MAX_RETRY + 1):
                elapsed = time.monotonic() - started_at
                remaining = self.TOTAL_TIMEOUT_SEC - elapsed
                if remaining <= 0:
                    break

                attempt_timeout = min(self.ATTEMPT_TIMEOUT_SEC, remaining)
                try:
                    response = await asyncio.wait_for(
                        self.provider.reply(context, reply_type),
                        timeout=attempt_timeout,
                    )
                    if not response.content.strip():
                        raise RuntimeError("Tutor provider returned empty content")
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
                        self.MAX_RETRY,
                        level.level_id,
                        exc,
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
                attempt=self.MAX_RETRY,
            )

        except Exception as exc:  # noqa: BLE001
            logger.error("Unexpected error in tutor reply: %s", exc, exc_info=True)
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

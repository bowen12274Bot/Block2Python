from __future__ import annotations

import asyncio
import json
from collections.abc import Sequence
from pathlib import Path

from block2python.ai import (
    ConversationHistoryCompressor,
    TeachingSkillLoader,
    TutorContextBuilder,
    TutorPolicy,
    TutorService,
)
from block2python.ai.models import ConversationTurn, TutorContext, TutorResponse
from block2python.ai.providers import TutorProvider
from block2python.contracts import LevelSpec, Submission


class _RecordingProvider(TutorProvider):
    def __init__(self, *, responses: Sequence[TutorResponse] | None = None, error: Exception | None = None) -> None:
        self.responses = list(responses or [TutorResponse(reply_type="next_step_hint", content="Try step one")])
        self.error = error
        self.calls: list[tuple[TutorContext, str]] = []

    async def reply(self, context: TutorContext, reply_type: str) -> TutorResponse:
        self.calls.append((context, reply_type))
        if self.error is not None:
            raise self.error
        if self.responses:
            return self.responses.pop(0)
        return TutorResponse(reply_type="next_step_hint", content="fallback")


class _SlowProvider(TutorProvider):
    async def reply(self, context: TutorContext, reply_type: str) -> TutorResponse:
        await asyncio.sleep(0.03)
        return TutorResponse(reply_type=reply_type, content="late")


def _write_json(path: Path, payload: dict[str, object]) -> None:
    path.write_text(json.dumps(payload), encoding="utf-8")


def _build_service(tmp_path: Path, provider: TutorProvider) -> TutorService:
    skills_dir = tmp_path / "skills"
    skills_dir.mkdir()
    _write_json(
        skills_dir / "io.json",
        {
            "skill_id": "io",
            "title": "IO",
            "hint_ladder": ["Read input", "Print output"],
        },
    )

    loader = TeachingSkillLoader(skills_dir=skills_dir)
    return TutorService(
        skill_loader=loader,
        context_builder=TutorContextBuilder(skill_loader=loader),
        policy=TutorPolicy(),
        provider=provider,
    )


def test_service_reply_success(tmp_path: Path) -> None:
    provider = _RecordingProvider(
        responses=[TutorResponse(reply_type="next_step_hint", content="Check input first")]
    )
    service = _build_service(tmp_path, provider)

    level = LevelSpec(level_id="lv-1", title="Level 1", teaching_skill_ids=("io",))
    submission = Submission(level_id="lv-1", python_code="print(1)")

    result = asyncio.run(
        service.reply(
            level=level,
            submission=submission,
            question="How to start?",
        )
    )

    assert result.reply_type == "next_step_hint"
    assert result.content == "Check input first"
    assert result.metadata["attempt"] == 1
    assert "missing_skill_ids" not in result.metadata
    assert len(provider.calls) == 1


def test_service_skips_missing_skill_and_still_replies(tmp_path: Path) -> None:
    provider = _RecordingProvider()
    service = _build_service(tmp_path, provider)

    level = LevelSpec(level_id="lv-1", title="Level 1", teaching_skill_ids=("missing-skill",))
    submission = Submission(level_id="lv-1", python_code="print(1)")

    result = asyncio.run(service.reply(level=level, submission=submission, question="help"))

    assert result.reply_type == "next_step_hint"
    assert result.metadata["missing_skill_ids"] == ["missing-skill"]


def test_service_returns_solution_refusal_without_calling_provider(tmp_path: Path) -> None:
    provider = _RecordingProvider()
    service = _build_service(tmp_path, provider)

    level = LevelSpec(level_id="lv-1", title="Level 1", tutor_policy={"allow_full_solution": False})
    submission = Submission(level_id="lv-1", python_code="print(1)")

    result = asyncio.run(
        service.reply(
            level=level,
            submission=submission,
            question="Please give me full solution",
        )
    )

    assert result.reply_type == "solution_refusal"
    assert result.metadata["provider"] == "policy"
    assert len(provider.calls) == 0


def test_service_retries_and_returns_unavailable(tmp_path: Path) -> None:
    provider = _RecordingProvider(error=RuntimeError("provider down"))
    service = _build_service(tmp_path, provider)
    service.MAX_RETRY = 2
    service.ATTEMPT_TIMEOUT_SEC = 0.1
    service.TOTAL_TIMEOUT_SEC = 0.2

    level = LevelSpec(level_id="lv-1", title="Level 1")
    submission = Submission(level_id="lv-1", python_code="print(1)")

    result = asyncio.run(service.reply(level=level, submission=submission, question="help"))

    assert result.reply_type == "scope_refusal"
    assert result.metadata["error_code"] == "provider_unavailable"
    assert result.metadata["attempt"] == 2
    assert len(provider.calls) == 2


def test_service_applies_history_compression(tmp_path: Path) -> None:
    provider = _RecordingProvider()
    service = _build_service(tmp_path, provider)
    service.history_compressor = ConversationHistoryCompressor(
        compress_trigger_tokens=10,
        target_tokens=10,
        keep_recent_turns=1,
    )

    level = LevelSpec(level_id="lv-1", title="Level 1")
    submission = Submission(level_id="lv-1", python_code="print(1)")

    history = [
        ConversationTurn(role="user", content="x" * 120),
        ConversationTurn(role="assistant", content="y" * 120),
        ConversationTurn(role="user", content="z" * 120),
    ]

    result = asyncio.run(
        service.reply(
            level=level,
            submission=submission,
            question="help",
            conversation_history=history,
            history_summary="old summary",
            submission_history=["analysis: missing print", "judge: WA on case 2"],
        )
    )

    called_context = provider.calls[0][0]
    assert len(called_context.conversation_history) == 1
    assert called_context.history_summary is not None
    assert "Summary of previous conversation" in called_context.history_summary
    assert called_context.submission_history == ("analysis: missing print", "judge: WA on case 2")
    assert result.metadata["history_compressed"] is True


def test_service_respects_total_timeout(tmp_path: Path) -> None:
    service = _build_service(tmp_path, _SlowProvider())
    service.MAX_RETRY = 3
    service.ATTEMPT_TIMEOUT_SEC = 0.01
    service.TOTAL_TIMEOUT_SEC = 0.02

    level = LevelSpec(level_id="lv-1", title="Level 1")
    submission = Submission(level_id="lv-1", python_code="print(1)")

    result = asyncio.run(service.reply(level=level, submission=submission, question="help"))

    assert result.reply_type == "scope_refusal"
    assert result.metadata["error_code"] == "provider_unavailable"

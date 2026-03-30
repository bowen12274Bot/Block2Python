from __future__ import annotations

import asyncio
from dataclasses import replace

from block2python.ai.models import TutorContext
from block2python.ai.providers import (
    LocalTemplateSelector,
    OpenAICompatibleProvider,
    StubTutorProvider,
    TemplateTutorProvider,
)


def _context(**overrides: object) -> TutorContext:
    base = TutorContext(
        level_id="lv-1",
        level_title="Level 1",
        level_prompt="Read input and print result.",
        learning_markdown="",
        hint_ladder=("Hint one", "Hint two"),
        analysis_status="PASS",
        judge_status="AC",
        student_question="How to start?",
        current_code="print(1)",
    )
    return replace(base, **overrides)


def test_stub_provider_returns_deterministic_message() -> None:
    provider = StubTutorProvider()
    reply = asyncio.run(provider.reply(_context(), "next_step_hint"))

    assert reply.reply_type == "next_step_hint"
    assert "reply_type=next_step_hint" in reply.content
    assert reply.metadata["provider"] == "stub"


def test_template_provider_uses_debug_signal() -> None:
    provider = TemplateTutorProvider()
    context = _context(analysis_violations=("syntax error near ':'",), analysis_status="FAIL")

    reply = asyncio.run(provider.reply(context, "debug_hint"))

    assert reply.reply_type == "debug_hint"
    assert "syntax error" in reply.content
    assert reply.metadata["provider"] == "template"


def test_template_provider_debug_hint_uses_recent_feedback_when_no_error_signal() -> None:
    provider = TemplateTutorProvider()
    context = _context(submission_history=("judge: WA on case 3",), failed_cases_summary=None)

    reply = asyncio.run(provider.reply(context, "debug_hint"))

    assert reply.reply_type == "debug_hint"
    assert "latest feedback" in reply.content
    assert "WA on case 3" in reply.content


def test_local_selector_switches_to_concept_explanation() -> None:
    selector = LocalTemplateSelector()
    context = _context(student_question="What is a variable?")

    reply = asyncio.run(selector.reply(context, "next_step_hint"))

    assert reply.reply_type == "concept_explanation"
    assert reply.metadata["provider"] == "local_template_selector"
    assert reply.metadata["selected_reply_type"] == "concept_explanation"


def test_openai_compatible_provider_parses_payload_without_network() -> None:
    class FakeOpenAIProvider(OpenAICompatibleProvider):
        def _call_api(self, context: TutorContext, reply_type: str) -> dict[str, object]:
            return {
                "choices": [{"message": {"content": "Use one variable and print result."}}],
                "usage": {"prompt_tokens": 12, "completion_tokens": 8},
            }

    provider = FakeOpenAIProvider(
        endpoint_url="https://example.invalid/v1/chat/completions",
        model="fake-model",
        api_key="fake-key",
    )

    reply = asyncio.run(provider.reply(_context(), "next_step_hint"))

    assert reply.reply_type == "next_step_hint"
    assert "Use one variable" in reply.content
    assert reply.metadata["provider"] == "openai_compatible"
    assert reply.metadata["usage"]["prompt_tokens"] == 12

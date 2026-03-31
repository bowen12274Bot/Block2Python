from __future__ import annotations

import asyncio
import json
from dataclasses import replace

from block2python.ai.models import TutorContext
from block2python.ai.providers import base as provider_base
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
    assert reply.metadata["provider"] == "temple_template"


def test_template_provider_debug_hint_uses_recent_feedback_when_no_error_signal() -> None:
    provider = TemplateTutorProvider()
    context = _context(submission_history=("judge: WA on case 3",), failed_cases_summary=None)

    reply = asyncio.run(provider.reply(context, "debug_hint"))

    assert reply.reply_type == "debug_hint"
    assert "最新一次回饋" in reply.content
    assert "WA on case 3" in reply.content


def test_template_provider_debug_hint_prefers_runtime_error_signal_for_re() -> None:
    provider = TemplateTutorProvider()
    context = _context(
        judge_status="RE",
        failed_cases_summary="Case 1: expected='Hello, Fyfuv!', actual=''",
        analysis_violations=(),
    )

    reply = asyncio.run(provider.reply(context, "debug_hint"))

    assert reply.reply_type == "debug_hint"
    assert "執行期錯誤" in reply.content
    assert reply.metadata["reason_code"] == "debug_runtime_error"


def test_local_selector_switches_to_concept_explanation() -> None:
    selector = LocalTemplateSelector()
    context = _context(student_question="What is a variable?")

    reply = asyncio.run(selector.reply(context, "next_step_hint"))

    assert reply.reply_type == "concept_explanation"
    assert reply.metadata["provider"] == "temple"
    assert reply.metadata["selected_reply_type"] == "concept_explanation"


def test_local_selector_uses_model_selection_when_endpoint_configured() -> None:
    class FakeLocalSelector(LocalTemplateSelector):
        def _call_selector_api(self, context: TutorContext, reply_type: str) -> dict[str, object]:
            return {
                "choices": [
                    {
                        "message": {
                            "content": '{"reply_type": "debug_hint"}',
                        }
                    }
                ]
            }

    selector = FakeLocalSelector(endpoint_url="http://127.0.0.1:11434/v1/chat/completions")
    context = _context(student_question="I need the next step", judge_status="WA")

    reply = asyncio.run(selector.reply(context, "next_step_hint"))

    assert reply.reply_type == "debug_hint"
    assert reply.metadata["selected_reply_type"] == "debug_hint"
    assert reply.metadata["selector_source"] == "model"


def test_local_selector_falls_back_to_heuristic_when_model_call_fails() -> None:
    class FailingLocalSelector(LocalTemplateSelector):
        def _call_selector_api(self, context: TutorContext, reply_type: str) -> dict[str, object]:
            raise RuntimeError("selector failed")

    selector = FailingLocalSelector(endpoint_url="http://127.0.0.1:11434/v1/chat/completions")
    context = _context(student_question="What is a variable?", judge_status="WA")

    reply = asyncio.run(selector.reply(context, "next_step_hint"))

    assert reply.reply_type == "concept_explanation"
    assert reply.metadata["selector_source"] == "heuristic_fallback"


def test_local_selector_skips_remote_model_when_ac() -> None:
    class ExplodingLocalSelector(LocalTemplateSelector):
        def _call_selector_api(self, context: TutorContext, reply_type: str) -> dict[str, object]:
            raise AssertionError("selector api should not be called for AC short-circuit")

    selector = ExplodingLocalSelector(endpoint_url="http://127.0.0.1:11434/v1/chat/completions")
    context = _context(student_question="I need the next step", judge_status="AC")

    reply = asyncio.run(selector.reply(context, "next_step_hint"))

    assert reply.reply_type == "next_step_hint"
    assert reply.metadata["selector_source"] == "heuristic_ac"
    assert reply.metadata["selector_reason"] == "ac_short_circuit"


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
    assert reply.metadata["provider"] == "api_skill"
    assert reply.metadata["usage"]["prompt_tokens"] == 12


def test_openai_compatible_provider_allows_empty_api_key_and_includes_skill_table(monkeypatch) -> None:
    captured: dict[str, object] = {}

    class _FakeResponse:
        def __enter__(self) -> "_FakeResponse":
            return self

        def __exit__(self, exc_type, exc, tb) -> bool:  # noqa: ANN001
            _ = exc_type
            _ = exc
            _ = tb
            return False

        @staticmethod
        def read() -> bytes:
            return (
                '{"choices":[{"message":{"content":"收到，先從輸入變數開始。"}}],"usage":{"prompt_tokens":10,"completion_tokens":6}}'
            ).encode("utf-8")

    def _fake_urlopen(req, timeout: float):  # noqa: ANN001
        _ = timeout
        captured["headers"] = dict(req.header_items())
        captured["body"] = req.data.decode("utf-8") if isinstance(req.data, (bytes, bytearray)) else ""
        return _FakeResponse()

    monkeypatch.setattr(provider_base.request, "urlopen", _fake_urlopen)

    provider = OpenAICompatibleProvider(
        endpoint_url="http://127.0.0.1:11434/v1/chat/completions",
        model="qwen3.5:9b",
        api_key="",
    )
    context = _context(
        teaching_skill_id="variables",
        learning_goals=("Store input in a variable",),
        allowed_concepts=("input()", "print()"),
        forbidden_concepts=("import",),
        hint_ladder=("先把 input() 結果存到變數",),
        analysis_status="FAIL",
        judge_status="WA",
        failed_cases_summary="Case 1 mismatch",
    )

    reply = asyncio.run(provider.reply(context, "next_step_hint"))

    assert reply.reply_type == "next_step_hint"
    assert "輸入變數" in reply.content

    request_body = str(captured.get("body", ""))
    payload = json.loads(request_body)
    assert payload["temperature"] == 0
    assert isinstance(payload.get("max_tokens"), int)
    assert int(payload["max_tokens"]) == 512
    user_prompt = str(payload["messages"][1]["content"])
    assert "Skill table JSON" in user_prompt
    assert "teaching_skill_id" in user_prompt
    assert "hint_ladder" in user_prompt

    headers = captured.get("headers")
    assert isinstance(headers, dict)
    lowered = {str(key).lower(): str(value) for key, value in headers.items()}
    assert "authorization" not in lowered


def test_openai_compatible_provider_uses_reasoning_when_content_is_empty() -> None:
    class FakeOpenAIProvider(OpenAICompatibleProvider):
        def _call_api(self, context: TutorContext, reply_type: str) -> dict[str, object]:
            return {
                "choices": [
                    {
                        "message": {
                            "content": "",
                            "reasoning": "Thinking Process:\n\n1. Analyze\nFinal Answer: 先把 input() 的結果存進變數，再用 print 輸出。",
                        }
                    }
                ],
                "usage": {"prompt_tokens": 20, "completion_tokens": 12},
            }

    provider = FakeOpenAIProvider(
        endpoint_url="http://127.0.0.1:11434/v1/chat/completions",
        model="qwen3.5:9b",
        api_key="",
    )

    reply = asyncio.run(provider.reply(_context(), "next_step_hint"))

    assert reply.reply_type == "next_step_hint"
    assert "先把 input() 的結果存進變數" in reply.content
    assert reply.metadata["provider"] == "api_skill"
    assert reply.metadata["reasoning_fallback"] is True

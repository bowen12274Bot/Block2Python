from __future__ import annotations

from dataclasses import replace

from block2python.ai import TutorPolicy
from block2python.ai.models import TutorContext


def _context(**overrides: object) -> TutorContext:
    base = TutorContext(
        level_id="lv-1",
        level_title="Level 1",
        level_prompt="Prompt",
        learning_markdown="",
        analysis_status="PASS",
        judge_status="AC",
    )
    return replace(base, **overrides)


def test_policy_returns_solution_refusal_for_full_solution_request() -> None:
    policy = TutorPolicy()
    context = _context(allow_full_solution=False)

    assert policy.determine_reply_type(context, "Please give me full solution") == "solution_refusal"


def test_policy_returns_scope_refusal_for_forbidden_concept() -> None:
    policy = TutorPolicy()
    context = _context(allow_full_solution=True, forbidden_concepts=("import",))

    assert policy.determine_reply_type(context, "Can I use import random?") == "scope_refusal"


def test_policy_returns_debug_hint_when_analysis_failed() -> None:
    policy = TutorPolicy()
    context = _context(analysis_status="FAIL", judge_status="AC")

    assert policy.determine_reply_type(context, "what is variable") == "debug_hint"


def test_policy_returns_debug_hint_when_judge_failed() -> None:
    policy = TutorPolicy()
    context = _context(analysis_status="PASS", judge_status="WA")

    assert policy.determine_reply_type(context, "next step?") == "debug_hint"


def test_policy_returns_concept_explanation_for_concept_question() -> None:
    policy = TutorPolicy()
    context = _context()

    assert policy.determine_reply_type(context, "What is assignment in python?") == "concept_explanation"


def test_policy_returns_next_step_hint_by_default() -> None:
    policy = TutorPolicy()
    context = _context()

    assert policy.determine_reply_type(context, "I am stuck") == "next_step_hint"


def test_policy_allowed_content_projection() -> None:
    policy = TutorPolicy()
    context = _context(
        allow_full_solution=False,
        allowed_concepts=("print", "input"),
        forbidden_concepts=("import",),
        max_hint_steps=2,
        response_tone="friendly",
    )

    allowed = policy.get_allowed_content(context)
    assert allowed == {
        "allow_full_solution": False,
        "allowed_concepts": ["print", "input"],
        "forbidden_concepts": ["import"],
        "max_hint_steps": 2,
        "response_tone": "friendly",
    }

from __future__ import annotations

import json
from pathlib import Path

from block2python.ai import TeachingSkillLoader, TutorContextBuilder
from block2python.ai.models import (
    ConversationTurn,
    TeachingSkill,
    TeachingSkillAnswerStyle,
    TeachingSkillAppliesTo,
)
from block2python.contracts import (
    AnalysisResult,
    AnalysisStatus,
    CaseResult,
    ConceptPolicy,
    JudgeResult,
    JudgeStatus,
    LevelSpec,
    RuleViolation,
    Submission,
)


def _write_json(path: Path, payload: dict[str, object]) -> None:
    path.write_text(json.dumps(payload), encoding="utf-8")


def test_build_with_explicit_skill_and_policy_overrides() -> None:
    level = LevelSpec(
        level_id="lv-1",
        title="Level 1",
        prompt="Read two integers and print sum.",
        learning_markdown="Use input and print.",
        concept_policy=ConceptPolicy(allowed_concepts=("print",), forbidden_concepts=("import",)),
        tutor_policy={"allow_full_solution": False, "max_hint_steps": 2, "response_tone": "friendly"},
    )
    submission = Submission(level_id="lv-1", python_code="print(1)", block_json={"type": "workspace"})

    skill = TeachingSkill(
        skill_id="input-output-basics",
        title="Input Output",
        applies_to=TeachingSkillAppliesTo(level_ids=("lv-1",)),
        learning_goals=("Know IO",),
        allowed_concepts=("input",),
        forbidden_concepts=("eval",),
        hint_ladder=("Hint A", "Hint B", "Hint C"),
        answer_style=TeachingSkillAnswerStyle(tone="clear", max_steps=4, max_response_length=220),
    )

    analysis_result = AnalysisResult(
        status=AnalysisStatus.FAIL,
        violations=(RuleViolation(rule_id="x", message="missing print"),),
    )
    judge_result = JudgeResult(
        status=JudgeStatus.WA,
        failed_case_index=0,
        case_results=(
            CaseResult(
                status="FAIL",
                stdin="1 2\n",
                expected_stdout="3\n",
                actual_stdout="4\n",
            ),
        ),
    )

    builder = TutorContextBuilder()
    context = builder.build(
        level=level,
        submission=submission,
        analysis_result=analysis_result,
        judge_result=judge_result,
        question="How should I start?",
        skills=[skill],
    )

    assert context.teaching_skill_id == "input-output-basics"
    assert context.allow_full_solution is False
    assert context.max_hint_steps == 2
    assert context.response_tone == "friendly"
    assert context.hint_ladder == ("Hint A", "Hint B")
    assert set(context.allowed_concepts) == {"print", "input"}
    assert set(context.forbidden_concepts) == {"import", "eval"}
    assert context.analysis_status == "FAIL"
    assert context.analysis_violations == ("missing print",)
    assert context.judge_status == "WA"
    assert context.failed_cases_summary is not None
    assert "Case 1" in context.failed_cases_summary


def test_build_fallback_when_no_skill_available() -> None:
    level = LevelSpec(level_id="lv-2", title="Level 2", prompt="Say hello")
    submission = Submission(level_id="lv-2", python_code="print('hello')")

    context = TutorContextBuilder().build(level=level, submission=submission, question="help")

    assert context.teaching_skill_id is None
    assert context.learning_goals == ()
    assert len(context.hint_ladder) == 3
    assert context.allow_full_solution is False


def test_build_loads_skill_from_loader(tmp_path: Path) -> None:
    skills_dir = tmp_path / "skills"
    skills_dir.mkdir()
    _write_json(
        skills_dir / "io.json",
        {
            "skill_id": "io",
            "title": "IO",
            "hint_ladder": ["First hint", "Second hint"],
            "learning_goals": ["Read input"],
        },
    )

    loader = TeachingSkillLoader(skills_dir=skills_dir)
    level = LevelSpec(level_id="lv-io", title="Level IO", teaching_skill_ids=("io",))
    submission = Submission(level_id="lv-io", python_code="print(1)")

    context = TutorContextBuilder(skill_loader=loader).build(level=level, submission=submission)

    assert context.teaching_skill_id == "io"
    assert context.hint_ladder == ("First hint", "Second hint")
    assert context.learning_goals == ("Read input",)


def test_build_normalizes_conversation_history() -> None:
    level = LevelSpec(level_id="lv-3", title="Level 3")
    submission = Submission(level_id="lv-3", python_code="print(1)")

    context = TutorContextBuilder().build(
        level=level,
        submission=submission,
        conversation_history=[
            {"role": "user", "content": "  question  "},
            {"role": "assistant", "content": "answer"},
            {"role": "unknown", "content": "fallback role"},
            ConversationTurn(role="system", content="note"),
            {"role": "assistant", "content": "   "},
        ],
    )

    assert [turn.role for turn in context.conversation_history] == ["user", "assistant", "user", "system"]
    assert [turn.content for turn in context.conversation_history] == [
        "question",
        "answer",
        "fallback role",
        "note",
    ]


def test_build_normalizes_submission_history() -> None:
    level = LevelSpec(level_id="lv-4", title="Level 4")
    submission = Submission(level_id="lv-4", python_code="print(1)")

    context = TutorContextBuilder().build(
        level=level,
        submission=submission,
        submission_history=["  analysis: syntax error  ", "", "judge: WA on case 2"],
    )

    assert context.submission_history == ("analysis: syntax error", "judge: WA on case 2")

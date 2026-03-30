from __future__ import annotations

from collections.abc import Iterable, Mapping, Sequence
from typing import Any

from block2python.contracts import AnalysisResult, JudgeResult, LevelSpec, Submission

from .models import (
    ConversationTurn,
    TeachingSkill,
    TeachingSkillAnswerStyle,
    TutorContext,
)
from .teaching_skill_loader import TeachingSkillLoader


class TutorContextBuilder:
    def __init__(self, *, skill_loader: TeachingSkillLoader | None = None) -> None:
        self.skill_loader = skill_loader

    def build(
        self,
        *,
        level: LevelSpec,
        submission: Submission,
        analysis_result: AnalysisResult | None = None,
        judge_result: JudgeResult | None = None,
        question: str = "",
        skills: Sequence[TeachingSkill] | None = None,
        conversation_id: str | None = None,
        conversation_history: Sequence[ConversationTurn | Mapping[str, object]] | None = None,
        history_summary: str | None = None,
        submission_history: Sequence[str] | None = None,
    ) -> TutorContext:
        resolved_skills = list(skills or self._load_skills(level.teaching_skill_ids))
        primary_skill = resolved_skills[0] if resolved_skills else None

        tutor_policy = dict(level.tutor_policy)
        answer_style = self._resolve_answer_style(primary_skill, tutor_policy)
        max_hint_steps = _parse_positive_int(tutor_policy.get("max_hint_steps"), default=answer_style.max_steps)
        allow_full_solution = _parse_bool(tutor_policy.get("allow_full_solution"), default=False)

        hint_ladder = tuple(primary_skill.hint_ladder if primary_skill else ())
        if not hint_ladder:
            hint_ladder = _default_hint_ladder()
        hint_ladder = hint_ladder[:max_hint_steps]

        allowed_concepts = _dedupe(
            [
                *level.concept_policy.allowed_concepts,
                *(item for skill in resolved_skills for item in skill.allowed_concepts),
            ]
        )
        forbidden_concepts = _dedupe(
            [
                *level.concept_policy.forbidden_concepts,
                *(item for skill in resolved_skills for item in skill.forbidden_concepts),
            ]
        )

        refusal_rules = _dedupe(item for skill in resolved_skills for item in skill.refusal_rules)
        if not allow_full_solution:
            refusal_rules = _dedupe([*refusal_rules, "Do not provide a full solution."])

        learning_goals = _dedupe(item for skill in resolved_skills for item in skill.learning_goals)
        common_mistakes = tuple(item for skill in resolved_skills for item in skill.common_mistakes)

        analysis_status = analysis_result.status.value if analysis_result is not None else "UNKNOWN"
        analysis_violations = (
            tuple(violation.message for violation in analysis_result.violations)
            if analysis_result is not None
            else ()
        )

        judge_status = judge_result.status.value if judge_result is not None else "UNKNOWN"
        failed_cases_summary = _summarize_failed_case(judge_result)

        normalized_history = _normalize_history(conversation_history)
        normalized_submission_history = _normalize_submission_history(submission_history)

        response_tone = answer_style.tone
        if isinstance(tutor_policy.get("response_tone"), str) and tutor_policy["response_tone"].strip():
            response_tone = tutor_policy["response_tone"].strip()

        return TutorContext(
            level_id=level.level_id,
            level_title=level.title,
            level_prompt=level.prompt,
            learning_markdown=level.learning_markdown,
            learning_goals=learning_goals,
            teaching_skill_id=primary_skill.skill_id if primary_skill is not None else None,
            allowed_concepts=allowed_concepts,
            forbidden_concepts=forbidden_concepts,
            hint_ladder=hint_ladder,
            common_mistakes=common_mistakes,
            refusal_rules=refusal_rules,
            answer_style=answer_style,
            student_question=question,
            current_code=submission.python_code,
            current_blocks=dict(submission.block_json) if isinstance(submission.block_json, dict) else {},
            analysis_status=analysis_status,
            analysis_violations=analysis_violations,
            judge_status=judge_status,
            failed_cases_summary=failed_cases_summary,
            allow_full_solution=allow_full_solution,
            max_hint_steps=max_hint_steps,
            response_tone=response_tone,
            conversation_id=conversation_id,
            conversation_history=normalized_history,
            history_summary=history_summary,
            submission_history=normalized_submission_history,
        )

    def _load_skills(self, skill_ids: Sequence[str]) -> tuple[TeachingSkill, ...]:
        if self.skill_loader is None:
            return ()

        loaded: list[TeachingSkill] = []
        for skill_id in skill_ids:
            normalized_id = skill_id.strip()
            if not normalized_id:
                continue
            try:
                loaded.append(self.skill_loader.load_skill(normalized_id))
            except Exception:
                continue
        return tuple(loaded)

    @staticmethod
    def _resolve_answer_style(
        primary_skill: TeachingSkill | None,
        tutor_policy: Mapping[str, Any],
    ) -> TeachingSkillAnswerStyle:
        base = primary_skill.answer_style if primary_skill is not None else TeachingSkillAnswerStyle()
        tone = base.tone
        if isinstance(tutor_policy.get("response_tone"), str) and tutor_policy["response_tone"].strip():
            tone = tutor_policy["response_tone"].strip()

        max_steps = _parse_positive_int(tutor_policy.get("max_hint_steps"), default=base.max_steps)
        max_response_length = _parse_positive_int(
            tutor_policy.get("max_response_length"),
            default=base.max_response_length,
        )

        return TeachingSkillAnswerStyle(
            tone=tone,
            max_steps=max_steps,
            max_response_length=max_response_length,
        )


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


def _normalize_submission_history(submission_history: Sequence[str] | None) -> tuple[str, ...]:
    if not submission_history:
        return ()

    normalized: list[str] = []
    for entry in submission_history:
        if not isinstance(entry, str):
            continue
        trimmed = entry.strip()
        if not trimmed:
            continue
        normalized.append(trimmed)
    return tuple(normalized)


def _default_hint_ladder() -> tuple[str, ...]:
    return (
        "Start from the exact input and output requirements.",
        "Break the task into one small step and verify that step first.",
        "Run one tiny example and compare your output with the expected format.",
    )


def _summarize_failed_case(judge_result: JudgeResult | None) -> str | None:
    if judge_result is None:
        return None

    if judge_result.status.value == "AC":
        return None

    failed_index = judge_result.failed_case_index
    case = None

    if failed_index is not None and 0 <= failed_index < len(judge_result.case_results):
        case = judge_result.case_results[failed_index]
    else:
        for index, item in enumerate(judge_result.case_results):
            if item.status != "PASS":
                failed_index = index
                case = item
                break

    if case is None:
        summary = judge_result.summary.strip()
        return summary or None

    expected = _truncate_text(case.expected_stdout)
    actual = _truncate_text(case.actual_stdout)
    return f"Case {failed_index + 1}: expected={expected!r}, actual={actual!r}"


def _truncate_text(value: str, *, max_length: int = 60) -> str:
    if len(value) <= max_length:
        return value
    return value[: max_length - 3] + "..."


def _parse_positive_int(value: object, *, default: int) -> int:
    if value is None:
        return default
    if isinstance(value, bool):
        return default
    try:
        parsed = int(str(value))
    except ValueError:
        return default
    if parsed <= 0:
        return default
    return parsed


def _parse_bool(value: object, *, default: bool) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in {"1", "true", "yes", "y", "on"}:
            return True
        if lowered in {"0", "false", "no", "n", "off"}:
            return False
    return default


def _dedupe(items: Iterable[object] | object) -> tuple[str, ...]:
    if isinstance(items, str):
        source: Iterable[object] = (items,)
    elif isinstance(items, Iterable):
        source = items
    else:
        return ()

    seen: set[str] = set()
    result: list[str] = []
    for item in source:
        if not isinstance(item, str):
            continue
        normalized = item.strip()
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        result.append(normalized)
    return tuple(result)

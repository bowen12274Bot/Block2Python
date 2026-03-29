from __future__ import annotations

from collections.abc import Sequence

from .models import TutorContext, TutorReplyType


_DEFAULT_SOLUTION_KEYWORDS = (
    "full solution",
    "complete solution",
    "full code",
    "complete code",
    "give me the answer",
    "direct answer",
    "write it for me",
    "完整解答",
    "完整答案",
    "完整程式",
    "直接給我答案",
)

_DEFAULT_CONCEPT_KEYWORDS = (
    "what is",
    "why",
    "explain",
    "difference",
    "觀念",
    "為什麼",
    "是什麼",
    "怎麼理解",
)


class TutorPolicy:
    def __init__(
        self,
        *,
        solution_keywords: Sequence[str] = _DEFAULT_SOLUTION_KEYWORDS,
        concept_keywords: Sequence[str] = _DEFAULT_CONCEPT_KEYWORDS,
    ) -> None:
        self._solution_keywords = tuple(keyword.lower() for keyword in solution_keywords if keyword.strip())
        self._concept_keywords = tuple(keyword.lower() for keyword in concept_keywords if keyword.strip())

    def determine_reply_type(self, context: TutorContext, question: str) -> TutorReplyType:
        refusal = self.check_refusal_triggers(context, question)
        if refusal is not None:
            return refusal

        if context.analysis_status in {"FAIL", "SYNTAX_ERROR", "INTERNAL_ERROR"}:
            return "debug_hint"

        if context.judge_status in {"WA", "TLE", "MLE", "RE", "INTERNAL_ERROR"}:
            return "debug_hint"

        normalized = (question or context.student_question).strip().lower()
        if any(keyword in normalized for keyword in self._concept_keywords):
            return "concept_explanation"

        return "next_step_hint"

    def get_allowed_content(self, context: TutorContext) -> dict[str, object]:
        return {
            "allow_full_solution": context.allow_full_solution,
            "allowed_concepts": list(context.allowed_concepts),
            "forbidden_concepts": list(context.forbidden_concepts),
            "max_hint_steps": context.max_hint_steps,
            "response_tone": context.response_tone,
        }

    def check_refusal_triggers(self, context: TutorContext, question: str) -> TutorReplyType | None:
        normalized_question = (question or context.student_question).strip().lower()

        if not context.allow_full_solution and any(
            keyword in normalized_question for keyword in self._solution_keywords
        ):
            return "solution_refusal"

        lowered_forbidden = tuple(item.lower() for item in context.forbidden_concepts)
        if any(concept and concept in normalized_question for concept in lowered_forbidden):
            return "scope_refusal"

        return None

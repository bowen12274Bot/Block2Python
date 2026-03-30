from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Literal

from block2python.contracts import AnalysisResult, JudgeResult


StudentLevel = Literal["beginner", "intermediate", "advanced"]
TutorReplyType = Literal[
    "concept_explanation",
    "next_step_hint",
    "debug_hint",
    "scope_refusal",
    "solution_refusal",
]


@dataclass(frozen=True, slots=True)
class TeachingSkillAppliesTo:
    level_ids: tuple[str, ...] = ()
    concepts: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class TeachingSkillMistake:
    pattern: str
    diagnosis: str
    hint: str


@dataclass(frozen=True, slots=True)
class TeachingSkillAnswerStyle:
    tone: str = "clear"
    max_steps: int = 3
    max_response_length: int = 500


@dataclass(frozen=True, slots=True)
class TeachingSkill:
    skill_id: str
    title: str
    version: str | None = None
    description: str = ""
    applies_to: TeachingSkillAppliesTo = field(default_factory=TeachingSkillAppliesTo)
    student_level: StudentLevel = "beginner"
    learning_goals: tuple[str, ...] = ()
    allowed_concepts: tuple[str, ...] = ()
    forbidden_concepts: tuple[str, ...] = ()
    hint_ladder: tuple[str, ...] = ()
    common_mistakes: tuple[TeachingSkillMistake, ...] = ()
    refusal_rules: tuple[str, ...] = ()
    answer_style: TeachingSkillAnswerStyle = field(default_factory=TeachingSkillAnswerStyle)
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class ConversationTurn:
    role: Literal["user", "assistant", "system"]
    content: str


@dataclass(frozen=True, slots=True)
class TutorRequest:
    level_id: str
    provider: str
    user_question: str
    current_code: str
    current_blocks: dict[str, Any] = field(default_factory=dict)
    conversation_id: str | None = None
    conversation_history: tuple[ConversationTurn, ...] = ()
    history_summary: str | None = None
    analysis_result: AnalysisResult | None = None
    judge_result: JudgeResult | None = None
    submission_history: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class TutorResponse:
    reply_type: TutorReplyType
    content: str
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class TutorContext:
    level_id: str
    level_title: str
    level_prompt: str
    learning_markdown: str
    learning_goals: tuple[str, ...] = ()
    teaching_skill_id: str | None = None
    allowed_concepts: tuple[str, ...] = ()
    forbidden_concepts: tuple[str, ...] = ()
    hint_ladder: tuple[str, ...] = ()
    common_mistakes: tuple[TeachingSkillMistake, ...] = ()
    refusal_rules: tuple[str, ...] = ()
    answer_style: TeachingSkillAnswerStyle = field(default_factory=TeachingSkillAnswerStyle)
    student_question: str = ""
    current_code: str = ""
    current_blocks: dict[str, Any] = field(default_factory=dict)
    analysis_status: str = "UNKNOWN"
    analysis_violations: tuple[str, ...] = ()
    judge_status: str = "UNKNOWN"
    failed_cases_summary: str | None = None
    allow_full_solution: bool = False
    max_hint_steps: int = 3
    response_tone: str = "clear"
    conversation_id: str | None = None
    conversation_history: tuple[ConversationTurn, ...] = ()
    history_summary: str | None = None
    submission_history: tuple[str, ...] = ()

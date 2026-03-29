from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Literal


StudentLevel = Literal["beginner", "intermediate", "advanced"]


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

from __future__ import annotations

import json
import logging
from pathlib import Path

from .models import (
    TeachingSkill,
    TeachingSkillAnswerStyle,
    TeachingSkillAppliesTo,
    TeachingSkillMistake,
)

logger = logging.getLogger(__name__)

_ALLOWED_STUDENT_LEVELS = {"beginner", "intermediate", "advanced"}
_ALLOWED_TONES = {"clear", "friendly", "formal"}


class TeachingSkillValidationError(ValueError):
    """Raised when a teaching skill file is malformed."""


class TeachingSkillLoader:
    def __init__(self, skills_dir: Path):
        self.skills_dir = skills_dir
        self._cache: dict[str, TeachingSkill] = {}

    def load_skill(self, skill_id: str) -> TeachingSkill:
        normalized_id = skill_id.strip()
        if not normalized_id:
            raise TeachingSkillValidationError("skill_id must not be empty")

        cached = self._cache.get(normalized_id)
        if cached is not None:
            return cached

        file_path = self.skills_dir / f"{normalized_id}.json"
        if not file_path.exists():
            raise FileNotFoundError(f"Teaching skill file not found: {file_path}")

        skill = _load_skill_file(file_path)
        if skill.skill_id != normalized_id:
            raise TeachingSkillValidationError(
                f"Skill id mismatch for {file_path.name}: expected '{normalized_id}', got '{skill.skill_id}'"
            )

        self._cache[normalized_id] = skill
        return skill

    def load_skills_for_level(self, level_id: str) -> list[TeachingSkill]:
        normalized_level = level_id.strip()
        if not normalized_level:
            return []

        matches: list[TeachingSkill] = []
        for skill in self._load_all_skills():
            if normalized_level in skill.applies_to.level_ids:
                matches.append(skill)
        return matches

    def find_skills_by_concept(self, concept: str) -> list[TeachingSkill]:
        normalized = concept.strip().lower()
        if not normalized:
            return []

        matches: list[TeachingSkill] = []
        for skill in self._load_all_skills():
            applies_to_concepts = {item.lower() for item in skill.applies_to.concepts}
            allowed_concepts = {item.lower() for item in skill.allowed_concepts}
            if normalized in applies_to_concepts or normalized in allowed_concepts:
                matches.append(skill)
        return matches

    def validate_skill_file(self, file_path: str | Path) -> bool:
        try:
            _load_skill_file(Path(file_path))
            return True
        except (OSError, json.JSONDecodeError, TeachingSkillValidationError):
            return False

    def _load_all_skills(self) -> list[TeachingSkill]:
        if not self.skills_dir.exists():
            return []

        loaded: list[TeachingSkill] = []
        for file_path in sorted(self.skills_dir.glob("*.json")):
            if file_path.name == "index.json":
                continue
            try:
                skill = _load_skill_file(file_path)
            except (OSError, json.JSONDecodeError, TeachingSkillValidationError) as exc:
                logger.warning("Skipping invalid teaching skill file '%s': %s", file_path.name, exc)
                continue

            self._cache[skill.skill_id] = skill
            loaded.append(skill)
        return loaded


def _load_skill_file(file_path: Path) -> TeachingSkill:
    raw = json.loads(file_path.read_text(encoding="utf-8"))
    return _parse_skill(raw, file_path)


def _parse_skill(raw: object, file_path: Path) -> TeachingSkill:
    if not isinstance(raw, dict):
        raise TeachingSkillValidationError(f"Skill file must be an object: {file_path}")

    skill_id = _required_non_empty_str(raw.get("skill_id"), "skill_id", file_path)
    title = _required_non_empty_str(raw.get("title"), "title", file_path)
    version = _optional_str(raw.get("version"))
    description = _optional_str(raw.get("description")) or ""

    applies_to_raw = raw.get("applies_to", {})
    if applies_to_raw is None:
        applies_to_raw = {}
    if not isinstance(applies_to_raw, dict):
        raise TeachingSkillValidationError(f"applies_to must be an object: {file_path}")

    applies_to = TeachingSkillAppliesTo(
        level_ids=_string_tuple(applies_to_raw.get("level_ids"), "applies_to.level_ids", file_path),
        concepts=_string_tuple(applies_to_raw.get("concepts"), "applies_to.concepts", file_path),
    )

    student_level = _optional_str(raw.get("student_level")) or "beginner"
    if student_level not in _ALLOWED_STUDENT_LEVELS:
        raise TeachingSkillValidationError(
            f"student_level must be one of {_ALLOWED_STUDENT_LEVELS}: {file_path}"
        )

    learning_goals = _string_tuple(raw.get("learning_goals"), "learning_goals", file_path)
    allowed_concepts = _string_tuple(raw.get("allowed_concepts"), "allowed_concepts", file_path)
    forbidden_concepts = _string_tuple(raw.get("forbidden_concepts"), "forbidden_concepts", file_path)
    hint_ladder = _string_tuple(raw.get("hint_ladder"), "hint_ladder", file_path)
    if not hint_ladder:
        raise TeachingSkillValidationError(f"hint_ladder must not be empty: {file_path}")

    common_mistakes = _parse_common_mistakes(raw.get("common_mistakes", []), file_path)
    refusal_rules = _string_tuple(raw.get("refusal_rules"), "refusal_rules", file_path)
    answer_style = _parse_answer_style(raw.get("answer_style"), file_path)

    metadata_raw = raw.get("metadata", {})
    metadata = dict(metadata_raw) if isinstance(metadata_raw, dict) else {}

    return TeachingSkill(
        skill_id=skill_id,
        title=title,
        version=version,
        description=description,
        applies_to=applies_to,
        student_level=student_level,
        learning_goals=learning_goals,
        allowed_concepts=allowed_concepts,
        forbidden_concepts=forbidden_concepts,
        hint_ladder=hint_ladder,
        common_mistakes=common_mistakes,
        refusal_rules=refusal_rules,
        answer_style=answer_style,
        metadata=metadata,
    )


def _parse_common_mistakes(raw: object, file_path: Path) -> tuple[TeachingSkillMistake, ...]:
    if raw is None:
        return ()
    if not isinstance(raw, list):
        raise TeachingSkillValidationError(f"common_mistakes must be an array: {file_path}")

    mistakes: list[TeachingSkillMistake] = []
    for index, item in enumerate(raw):
        if not isinstance(item, dict):
            raise TeachingSkillValidationError(
                f"common_mistakes[{index}] must be an object: {file_path}"
            )
        mistakes.append(
            TeachingSkillMistake(
                pattern=_required_non_empty_str(item.get("pattern"), f"common_mistakes[{index}].pattern", file_path),
                diagnosis=_required_non_empty_str(
                    item.get("diagnosis"), f"common_mistakes[{index}].diagnosis", file_path
                ),
                hint=_required_non_empty_str(item.get("hint"), f"common_mistakes[{index}].hint", file_path),
            )
        )

    return tuple(mistakes)


def _parse_answer_style(raw: object, file_path: Path) -> TeachingSkillAnswerStyle:
    if raw is None:
        return TeachingSkillAnswerStyle()
    if not isinstance(raw, dict):
        raise TeachingSkillValidationError(f"answer_style must be an object: {file_path}")

    tone = _optional_str(raw.get("tone")) or "clear"
    if tone not in _ALLOWED_TONES:
        raise TeachingSkillValidationError(f"answer_style.tone must be one of {_ALLOWED_TONES}: {file_path}")

    max_steps = _parse_positive_int(raw.get("max_steps"), "answer_style.max_steps", file_path, default=3)
    max_response_length = _parse_positive_int(
        raw.get("max_response_length"),
        "answer_style.max_response_length",
        file_path,
        default=500,
    )

    return TeachingSkillAnswerStyle(
        tone=tone,
        max_steps=max_steps,
        max_response_length=max_response_length,
    )


def _parse_positive_int(value: object, field_name: str, file_path: Path, *, default: int) -> int:
    if value is None:
        return default
    if isinstance(value, bool):
        raise TeachingSkillValidationError(f"{field_name} must be a positive integer: {file_path}")

    try:
        parsed = int(str(value))
    except ValueError as exc:
        raise TeachingSkillValidationError(f"{field_name} must be a positive integer: {file_path}") from exc

    if parsed <= 0:
        raise TeachingSkillValidationError(f"{field_name} must be a positive integer: {file_path}")
    return parsed


def _string_tuple(raw: object, field_name: str, file_path: Path) -> tuple[str, ...]:
    if raw is None:
        return ()
    if not isinstance(raw, list):
        raise TeachingSkillValidationError(f"{field_name} must be an array: {file_path}")

    normalized: list[str] = []
    for index, item in enumerate(raw):
        if not isinstance(item, str) or not item.strip():
            raise TeachingSkillValidationError(
                f"{field_name}[{index}] must be a non-empty string: {file_path}"
            )
        normalized.append(item.strip())
    return tuple(normalized)


def _required_non_empty_str(value: object, field_name: str, file_path: Path) -> str:
    parsed = _optional_str(value)
    if parsed is None:
        raise TeachingSkillValidationError(f"{field_name} must be a non-empty string: {file_path}")
    return parsed


def _optional_str(value: object) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str):
        return None
    parsed = value.strip()
    return parsed if parsed else None

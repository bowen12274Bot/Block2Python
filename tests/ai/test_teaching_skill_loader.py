from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pytest

from block2python.ai import TeachingSkillLoader, TeachingSkillValidationError
from block2python.content import load_levels


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload), encoding="utf-8")


@pytest.fixture
def temp_skills_dir(tmp_path: Path) -> Path:
    skills_dir = tmp_path / "teaching_skills"
    skills_dir.mkdir()

    _write_json(
        skills_dir / "input-output-basics.json",
        {
            "skill_id": "input-output-basics",
            "title": "Input Output Basics",
            "applies_to": {
                "level_ids": ["group-01-demo"],
                "concepts": ["input", "output"],
            },
            "hint_ladder": [
                "Hint 1",
                "Hint 2",
            ],
            "allowed_concepts": ["input()", "print()"],
        },
    )

    _write_json(
        skills_dir / "variables.json",
        {
            "skill_id": "variables",
            "title": "Variables",
            "applies_to": {
                "level_ids": ["group-01-practice-01"],
                "concepts": ["variables"],
            },
            "hint_ladder": [
                "Keep one variable name.",
            ],
            "allowed_concepts": ["assignment"],
            "answer_style": {
                "tone": "clear",
                "max_steps": 3,
                "max_response_length": 200,
            },
        },
    )

    return skills_dir


class TestTeachingSkillLoader:
    def test_load_skill_success(self, temp_skills_dir: Path):
        loader = TeachingSkillLoader(skills_dir=temp_skills_dir)

        skill = loader.load_skill("input-output-basics")

        assert skill.skill_id == "input-output-basics"
        assert skill.title == "Input Output Basics"
        assert skill.applies_to.level_ids == ("group-01-demo",)
        assert skill.hint_ladder == ("Hint 1", "Hint 2")

    def test_load_skill_not_found(self, temp_skills_dir: Path):
        loader = TeachingSkillLoader(skills_dir=temp_skills_dir)

        with pytest.raises(FileNotFoundError):
            loader.load_skill("missing-skill")

    def test_load_skill_id_mismatch(self, tmp_path: Path):
        skills_dir = tmp_path / "skills"
        skills_dir.mkdir()
        _write_json(
            skills_dir / "expected-id.json",
            {
                "skill_id": "other-id",
                "title": "Mismatch",
                "hint_ladder": ["h1"],
            },
        )

        loader = TeachingSkillLoader(skills_dir=skills_dir)
        with pytest.raises(TeachingSkillValidationError):
            loader.load_skill("expected-id")

    def test_load_skills_for_level(self, temp_skills_dir: Path):
        loader = TeachingSkillLoader(skills_dir=temp_skills_dir)

        skills = loader.load_skills_for_level("group-01-demo")

        assert [skill.skill_id for skill in skills] == ["input-output-basics"]

    def test_find_skills_by_concept(self, temp_skills_dir: Path):
        loader = TeachingSkillLoader(skills_dir=temp_skills_dir)

        skills = loader.find_skills_by_concept("variables")

        assert [skill.skill_id for skill in skills] == ["variables"]

    def test_validate_skill_file(self, tmp_path: Path):
        skills_dir = tmp_path / "skills"
        skills_dir.mkdir()

        valid_file = skills_dir / "valid.json"
        _write_json(
            valid_file,
            {
                "skill_id": "valid",
                "title": "Valid",
                "hint_ladder": ["h1"],
            },
        )

        invalid_file = skills_dir / "invalid.json"
        invalid_file.write_text("{invalid", encoding="utf-8")

        loader = TeachingSkillLoader(skills_dir=skills_dir)
        assert loader.validate_skill_file(valid_file) is True
        assert loader.validate_skill_file(invalid_file) is False

    def test_load_skills_for_level_skips_invalid_files(self, tmp_path: Path):
        skills_dir = tmp_path / "skills"
        skills_dir.mkdir()

        _write_json(
            skills_dir / "good.json",
            {
                "skill_id": "good",
                "title": "Good",
                "applies_to": {"level_ids": ["lv-1"]},
                "hint_ladder": ["h1"],
            },
        )
        (skills_dir / "broken.json").write_text("{not-json", encoding="utf-8")

        loader = TeachingSkillLoader(skills_dir=skills_dir)
        skills = loader.load_skills_for_level("lv-1")

        assert [skill.skill_id for skill in skills] == ["good"]


def test_assets_group_01_levels_have_teaching_skills() -> None:
    levels = load_levels(Path("assets/levels"))
    loader = TeachingSkillLoader(skills_dir=Path("assets/teaching_skills"))

    assert levels["group-01-demo"].teaching_skill_ids == ("input-output-basics",)
    assert levels["group-01-practice-01"].teaching_skill_ids == ("variables",)

    demo_skills = loader.load_skills_for_level("group-01-demo")
    practice_skills = loader.load_skills_for_level("group-01-practice-01")

    assert {skill.skill_id for skill in demo_skills} == {"input-output-basics"}
    assert {skill.skill_id for skill in practice_skills} == {"variables"}

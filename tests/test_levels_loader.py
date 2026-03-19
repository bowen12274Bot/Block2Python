"""Tests for levels loader and judge_policy parsing."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from block2python.app.levels_loader import load_levels
from block2python.contracts import JudgePolicy


@pytest.fixture
def temp_levels_dir(tmp_path: Path) -> Path:
    """Create temporary levels directory with test data."""
    levels_dir = tmp_path / "levels"
    levels_dir.mkdir()

    index = {
        "levels": [
            {"id": "test-1", "file": "test-1.json"},
        ]
    }
    (levels_dir / "index.json").write_text(json.dumps(index))

    level_data = {
        "level_id": "test-1",
        "title": "Test Level",
        "prompt": "Test prompt",
        "testcases": [{"stdin": "1\n", "expected_stdout": "2\n"}],
        "judge_policy": {
            "time_limit_ms": 3000,
            "output_normalization": {
                "strip_trailing_whitespace": False,
                "normalize_newlines_to_lf": True,
                "strip_trailing_newline": False,
            },
        },
    }
    (levels_dir / "test-1.json").write_text(json.dumps(level_data))
    return levels_dir


class TestLevelsLoader:
    """Test level loading and judge_policy parsing."""

    def test_load_judge_policy(self, temp_levels_dir: Path):
        levels = load_levels(temp_levels_dir)
        assert "test-1" in levels
        level = levels["test-1"]
        assert level.judge_policy.time_limit_ms == 3000
        assert level.judge_policy.memory_limit_kb is None
        assert level.judge_policy.output_normalization.normalize_newlines_to_lf is True
        assert level.judge_policy.output_normalization.strip_trailing_whitespace is False

    def test_default_judge_policy_when_missing(self, tmp_path: Path):
        levels_dir = tmp_path / "levels2"
        levels_dir.mkdir()
        index = {"levels": [{"id": "minimal", "file": "minimal.json"}]}
        (levels_dir / "index.json").write_text(json.dumps(index))
        minimal = {"level_id": "minimal", "title": "Minimal"}
        (levels_dir / "minimal.json").write_text(json.dumps(minimal))

        levels = load_levels(levels_dir)
        assert "minimal" in levels
        # Should use default JudgePolicy
        assert levels["minimal"].judge_policy.time_limit_ms == JudgePolicy().time_limit_ms

    def test_testcases_loaded(self, temp_levels_dir: Path):
        levels = load_levels(temp_levels_dir)
        level = levels["test-1"]
        assert len(level.testcases) == 1
        assert level.testcases[0].stdin == "1\n"
        assert level.testcases[0].expected_stdout == "2\n"

    def test_load_yaml_level_with_in_out_files(self, tmp_path: Path):
        levels_dir = tmp_path / "levels-yaml"
        levels_dir.mkdir()
        cases_dir = levels_dir / "cases"
        cases_dir.mkdir()

        (levels_dir / "index.yaml").write_text(
            "levels:\n"
            "  - id: yaml-level\n"
            "    file: yaml-level.yaml\n",
            encoding="utf-8",
        )
        (cases_dir / "sample-1.in").write_text("4 5\n", encoding="utf-8")
        (cases_dir / "sample-1.out").write_text("9\n", encoding="utf-8")
        (levels_dir / "yaml-level.yaml").write_text(
            "level_id: yaml-level\n"
            "title: YAML Level\n"
            "prompt: add numbers\n"
            "testcase_dir: cases\n"
            "judge_policy:\n"
            "  time_limit_ms: 1200\n"
            "  memory_limit_mb: 64\n",
            encoding="utf-8",
        )

        levels = load_levels(levels_dir)
        level = levels["yaml-level"]
        assert len(level.testcases) == 1
        assert level.testcases[0].name == "sample-1"
        assert level.testcases[0].stdin == "4 5\n"
        assert level.testcases[0].expected_stdout == "9\n"
        assert level.judge_policy.time_limit_ms == 1200
        assert level.judge_policy.memory_limit_kb == 64 * 1024

    def test_load_explicit_file_backed_testcases(self, tmp_path: Path):
        levels_dir = tmp_path / "levels-file-ref"
        levels_dir.mkdir()
        case_dir = levels_dir / "refs"
        case_dir.mkdir()

        (levels_dir / "index.json").write_text(json.dumps({"levels": [{"id": "ref-level", "file": "ref-level.json"}]}))
        (case_dir / "case-a.in").write_text("10\n", encoding="utf-8")
        (case_dir / "case-a.out").write_text("11\n", encoding="utf-8")
        (levels_dir / "ref-level.json").write_text(
            json.dumps(
                {
                    "level_id": "ref-level",
                    "title": "Referenced Files",
                    "testcases": [
                        {
                            "name": "case-a",
                            "stdin_file": "refs/case-a.in",
                            "expected_stdout_file": "refs/case-a.out",
                        }
                    ],
                    "judge_policy": {"memory_limit_kb": 2048},
                }
            ),
            encoding="utf-8",
        )

        levels = load_levels(levels_dir)
        level = levels["ref-level"]
        assert level.testcases[0].name == "case-a"
        assert level.testcases[0].stdin == "10\n"
        assert level.testcases[0].expected_stdout == "11\n"
        assert level.judge_policy.memory_limit_kb == 2048


def test_assets_levels_include_three_group_scaffolds() -> None:
    levels = load_levels(Path("assets/levels"))

    assert "group-01-demo" in levels
    assert "group-02-demo" in levels
    assert "group-03-demo" in levels

    assert levels["group-01-demo"].next_level_ids == ("group-01-practice-01",)
    assert levels["group-01-practice-01"].next_level_ids == ("group-01-practice-02",)
    assert levels["group-01-practice-05"].next_level_ids == ()

    assert levels["group-02-practice-03"].prerequisite_level_ids == ("group-02-practice-02",)
    assert len(levels["group-03-demo"].testcases) == 1

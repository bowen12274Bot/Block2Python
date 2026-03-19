"""Tests for AppCore submit workflow and judge integration."""

from __future__ import annotations

import pytest

from block2python.level_play import AppCore, LevelState
from block2python.contracts import JudgeStatus, LevelSpec, Submission, Testcase as JudgeTestcase
from block2python.judge import StubJudge


@pytest.fixture
def simple_levels() -> dict[str, LevelSpec]:
    """Simple level set for testing."""
    return {
        "level-1": LevelSpec(
            level_id="level-1",
            title="First Level",
            prompt="",
            testcases=(JudgeTestcase(stdin="", expected_stdout="hello\n"),),
        ),
        "level-2": LevelSpec(
            level_id="level-2",
            title="Second Level",
            prompt="",
            prerequisite_level_ids=("level-1",),
            testcases=(JudgeTestcase(stdin="", expected_stdout="world\n"),),
        ),
    }


class TestAppCore:
    """Test AppCore submission workflow and state management."""

    def test_initial_state(self, simple_levels):
        app = AppCore(simple_levels)
        views = app.list_levels()
        assert len(views) == 2
        assert views[0].state == LevelState.UNLOCKED
        assert views[1].state == LevelState.LOCKED

    def test_submit_requires_block_passed(self, simple_levels):
        app = AppCore(simple_levels)
        sub = Submission(level_id="level-1", python_code="print('hello')")
        outcome = app.submit(sub)
        assert outcome.block_passed is False
        assert outcome.cleared is False

    def test_submit_after_block_passed(self, simple_levels):
        app = AppCore(simple_levels)
        app.mark_block_passed("level-1")
        sub = Submission(level_id="level-1", python_code="print('hello')")
        outcome = app.submit(sub)
        # StubJudge will return AC if configured in level metadata
        assert outcome.block_passed is True

    def test_level_unlock_after_clear(self, simple_levels):
        app = AppCore(simple_levels)
        app.mark_block_passed("level-1")

        # Configure stub to return AC
        simple_levels["level-1"].metadata["stub_judge"] = {"status": "AC"}
        app = AppCore(simple_levels, judge=StubJudge())
        app.mark_block_passed("level-1")

        sub = Submission(level_id="level-1", python_code="print('hello')")
        outcome = app.submit(sub)
        assert outcome.cleared is True

        views = app.list_levels()
        level_2_state = next(v.state for v in views if v.level_id == "level-2")
        assert level_2_state == LevelState.UNLOCKED

    def test_unknown_level_id(self, simple_levels):
        app = AppCore(simple_levels)
        sub = Submission(level_id="nonexistent", python_code="")
        outcome = app.submit(sub)
        assert outcome.judge.status == JudgeStatus.INTERNAL_ERROR


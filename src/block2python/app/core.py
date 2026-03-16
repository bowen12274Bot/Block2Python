from __future__ import annotations

from dataclasses import dataclass
from enum import Enum

from block2python.analysis import Analyzer, AstAnalyzer
from block2python.contracts import AnalysisResult, AnalysisStatus, JudgeResult, JudgeStatus, LevelSpec, Submission
from block2python.judge import Judge, StubJudge

from .progress import InMemoryProgress, ProgressStore


class LevelState(str, Enum):
    LOCKED = "LOCKED"
    UNLOCKED = "UNLOCKED"
    CLEARED = "CLEARED"


@dataclass(frozen=True, slots=True)
class LevelView:
    level_id: str
    title: str
    state: LevelState


@dataclass(frozen=True, slots=True)
class SubmitOutcome:
    analysis: AnalysisResult
    judge: JudgeResult
    cleared: bool
    block_passed: bool


class AppCore:
    def __init__(
        self,
        levels: dict[str, LevelSpec],
        *,
        judge: Judge | None = None,
        analyzer: Analyzer | None = None,
        progress: ProgressStore | None = None,
    ) -> None:
        self._levels = levels
        self._judge = judge or StubJudge()
        self._analyzer = analyzer or AstAnalyzer()
        self._progress = progress or InMemoryProgress.empty()

    def list_levels(self) -> tuple[LevelView, ...]:
        views: list[LevelView] = []
        for level in self._levels.values():
            views.append(LevelView(level_id=level.level_id, title=level.title, state=self._state_of(level)))
        return tuple(views)

    def submit(self, submission: Submission) -> SubmitOutcome:
        level = self._levels.get(submission.level_id)
        if level is None:
            analysis = AnalysisResult(status=AnalysisStatus.INTERNAL_ERROR, summary="Unknown level_id")
            judge = JudgeResult(status=JudgeStatus.INTERNAL_ERROR, summary="Unknown level_id")
            return SubmitOutcome(analysis=analysis, judge=judge, cleared=False, block_passed=False)

        if self._state_of(level) is LevelState.LOCKED:
            analysis = AnalysisResult(status=AnalysisStatus.FAIL, summary="Level is locked")
            judge = JudgeResult(status=JudgeStatus.WA, summary="Level is locked")
            return SubmitOutcome(analysis=analysis, judge=judge, cleared=False, block_passed=False)

        if not self._progress.is_block_passed(level.level_id):
            analysis = AnalysisResult(status=AnalysisStatus.FAIL, summary="Block step not passed yet")
            judge = JudgeResult(status=JudgeStatus.WA, summary="Blocked (complete block step first)", debug={"skipped": True})
            return SubmitOutcome(analysis=analysis, judge=judge, cleared=False, block_passed=False)

        analysis = self._analyzer.analyze(submission, level)
        if analysis.status not in (AnalysisStatus.PASS,):
            judge = JudgeResult(status=JudgeStatus.WA, summary="Skipped judge due to analysis failure", debug={"skipped": True})
            return SubmitOutcome(analysis=analysis, judge=judge, cleared=False, block_passed=True)

        judge = self._judge.judge(submission, level)
        cleared = judge.status is JudgeStatus.AC
        if cleared:
            self._progress.mark_cleared(level.level_id)
        return SubmitOutcome(analysis=analysis, judge=judge, cleared=cleared, block_passed=True)

    def _state_of(self, level: LevelSpec) -> LevelState:
        if self._progress.is_cleared(level.level_id):
            return LevelState.CLEARED
        if not level.prerequisite_level_ids:
            return LevelState.UNLOCKED
        if all(self._progress.is_cleared(lid) for lid in level.prerequisite_level_ids):
            return LevelState.UNLOCKED
        return LevelState.LOCKED

    def mark_block_passed(self, level_id: str) -> bool:
        level = self._levels.get(level_id)
        if level is None:
            return False
        if self._state_of(level) is LevelState.LOCKED:
            return False
        self._progress.mark_block_passed(level_id)
        return True

    def is_block_passed(self, level_id: str) -> bool:
        return self._progress.is_block_passed(level_id)

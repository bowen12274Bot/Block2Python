from __future__ import annotations

from typing import Protocol

from block2python.contracts import AnalysisResult, LevelSpec, Submission


class Analyzer(Protocol):
    def analyze(self, submission: Submission, level: LevelSpec) -> AnalysisResult: ...


from __future__ import annotations

from typing import Protocol

from block2python.contracts import JudgeResult, LevelSpec, Submission


class Judge(Protocol):
    def judge(self, submission: Submission, level: LevelSpec) -> JudgeResult: ...


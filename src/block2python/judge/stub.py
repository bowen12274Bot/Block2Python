from __future__ import annotations

from typing import Any, cast

from block2python.contracts import JudgeResult, JudgeStatus, LevelSpec, Submission

from .api import Judge


class StubJudge(Judge):
    """
    A configurable fake judge used to bypass the real execution/sandbox design.

    Configuration (optional):
      - level.metadata["stub_judge"] = {"status": "AC"|"WA"|"TLE"|"RE", "summary": "..."}
    Default behavior: always AC.
    """

    def judge(self, submission: Submission, level: LevelSpec) -> JudgeResult:
        cfg = cast(dict[str, Any], level.metadata.get("stub_judge", {}))
        status_raw = str(cfg.get("status", JudgeStatus.AC.value)).upper()
        summary = str(cfg.get("summary", "StubJudge: execution/judge not implemented yet."))

        try:
            status = JudgeStatus(status_raw)
        except ValueError:
            status = JudgeStatus.INTERNAL_ERROR
            summary = f"StubJudge misconfigured status: {status_raw}"

        return JudgeResult(status=status, summary=summary, debug={"stub": True, "level_id": level.level_id})


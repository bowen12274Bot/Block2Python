from __future__ import annotations

from typing import Any, cast

from block2python.contracts import CaseResult, JudgeResult, JudgeStatus, LevelSpec, Submission, Testcase

from .api import Judge


class StubJudge(Judge):
    """
    A configurable fake judge used to bypass the real execution/sandbox design.

    Configuration (optional):
      - level.metadata["stub_judge"] = {
          "status": "AC"|"WA"|"TLE"|"RE",
          "summary": "...",
          "fail_case_index": 0,
          "actual_stdout_by_case": ["...", "..."]
        }

    Default behavior:
      - If testcases exist: mark all PASS and return AC with populated case_results.
      - If no testcases: return AC with empty case_results.
    """

    def judge(self, submission: Submission, level: LevelSpec) -> JudgeResult:
        cfg = cast(dict[str, Any], level.metadata.get("stub_judge", {}))
        status_raw = str(cfg.get("status", JudgeStatus.AC.value)).upper()
        summary = str(cfg.get("summary", "StubJudge: execution/judge not implemented yet."))
        fail_case_index = cfg.get("fail_case_index", None)
        actual_stdout_by_case = cfg.get("actual_stdout_by_case", None)

        try:
            status = JudgeStatus(status_raw)
        except ValueError:
            status = JudgeStatus.INTERNAL_ERROR
            summary = f"StubJudge misconfigured status: {status_raw}"

        case_results, derived_failed = _build_case_results(
            level.testcases,
            status=status,
            fail_case_index=fail_case_index,
            actual_stdout_by_case=actual_stdout_by_case,
        )

        failed_case_index = derived_failed
        if status is JudgeStatus.AC:
            failed_case_index = None

        return JudgeResult(
            status=status,
            summary=summary,
            case_results=case_results,
            failed_case_index=failed_case_index,
            debug={"stub": True, "level_id": level.level_id, "has_testcases": bool(level.testcases)},
        )


def _build_case_results(
    testcases: tuple[Testcase, ...],
    *,
    status: JudgeStatus,
    fail_case_index: object,
    actual_stdout_by_case: object,
) -> tuple[tuple[CaseResult, ...], int | None]:
    if not testcases:
        return (), None

    fail_index: int | None = None
    if isinstance(fail_case_index, int):
        fail_index = fail_case_index
    elif isinstance(fail_case_index, str) and fail_case_index.strip().isdigit():
        fail_index = int(fail_case_index.strip())

    actuals: list[str] | None = None
    if isinstance(actual_stdout_by_case, list):
        actuals = [str(x) for x in actual_stdout_by_case]

    results: list[CaseResult] = []
    derived_failed: int | None = None

    for i, tc in enumerate(testcases):
        expected = tc.expected_stdout
        actual = expected if actuals is None or i >= len(actuals) else actuals[i]

        if status is JudgeStatus.TLE:
            cr_status = "TIMEOUT"
            derived_failed = i if derived_failed is None else derived_failed
        elif status in (JudgeStatus.RE, JudgeStatus.INTERNAL_ERROR):
            cr_status = "ERROR"
            derived_failed = i if derived_failed is None else derived_failed
        elif status is JudgeStatus.WA:
            if fail_index is None or i == fail_index:
                cr_status = "FAIL"
                derived_failed = i if derived_failed is None else derived_failed
                if actual == expected:
                    actual = expected + " (stub WA)"
            else:
                cr_status = "PASS"
        else:
            cr_status = "PASS"

        results.append(
            CaseResult(
                status=cr_status,
                stdin=tc.stdin,
                expected_stdout=expected,
                actual_stdout=actual if cr_status != "PASS" else expected,
            )
        )

    return tuple(results), derived_failed

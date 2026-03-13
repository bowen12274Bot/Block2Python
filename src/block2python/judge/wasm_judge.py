from __future__ import annotations

from block2python.contracts import CaseResult, JudgeResult, JudgeStatus, LevelSpec, Submission

from .api import Judge
from .normalization import normalize_output
from .wasm_runner import ExecutionResult, WasmRunner


class WasmJudge(Judge):
    def __init__(self, runner: WasmRunner, *, fail_fast: bool = True) -> None:
        self._runner = runner
        self._fail_fast = fail_fast

    def judge(self, submission: Submission, level: LevelSpec) -> JudgeResult:
        if not level.testcases:
            return JudgeResult(
                status=JudgeStatus.AC,
                summary="No testcases configured.",
                case_results=(),
                debug={"runner": type(self._runner).__name__},
            )

        case_results: list[CaseResult] = []
        overall = JudgeStatus.AC
        failed_case_index: int | None = None

        for idx, tc in enumerate(level.testcases):
            execution = self._safe_execute(
                submission.python_code,
                tc.stdin,
                time_limit_ms=level.judge_policy.time_limit_ms,
                memory_limit_kb=level.judge_policy.memory_limit_kb,
            )

            case_result, case_judge_status = self._case_from_execution(execution, tc.expected_stdout, tc.stdin, level)
            case_results.append(case_result)

            if case_judge_status is JudgeStatus.AC:
                continue

            if failed_case_index is None:
                failed_case_index = idx
                overall = case_judge_status

            if self._fail_fast:
                break

        summary = _summary_from_status(overall, failed_case_index, len(case_results), len(level.testcases))

        return JudgeResult(
            status=overall,
            summary=summary,
            case_results=tuple(case_results),
            failed_case_index=failed_case_index,
            stdout=_first_non_empty([x.actual_stdout for x in case_results]),
            stderr=_first_non_empty([x.stderr for x in case_results]),
            elapsed_ms=_sum_elapsed_ms(case_results),
            debug={
                "runner": type(self._runner).__name__,
                "fail_fast": self._fail_fast,
                "configured_testcases": len(level.testcases),
                "executed_testcases": len(case_results),
            },
        )

    def _safe_execute(
        self,
        python_code: str,
        stdin_text: str,
        *,
        time_limit_ms: int,
        memory_limit_kb: int | None,
    ) -> ExecutionResult:
        try:
            return self._runner.execute(
                python_code,
                stdin_text,
                time_limit_ms=time_limit_ms,
                memory_limit_kb=memory_limit_kb,
            )
        except Exception as e:  # noqa: BLE001
            return ExecutionResult(internal_error=f"Runner exception: {e}")

    def _case_from_execution(
        self,
        execution: ExecutionResult,
        expected_stdout: str,
        stdin_text: str,
        level: LevelSpec,
    ) -> tuple[CaseResult, JudgeStatus]:
        if execution.timed_out:
            return (
                CaseResult(
                    status="TIMEOUT",
                    stdin=stdin_text,
                    expected_stdout=expected_stdout,
                    actual_stdout=execution.stdout,
                    stderr=execution.stderr,
                    exit_code=execution.exit_code,
                    elapsed_ms=execution.elapsed_ms,
                ),
                JudgeStatus.TLE,
            )

        if execution.memory_exceeded:
            return (
                CaseResult(
                    status="MEMORY_LIMIT",
                    stdin=stdin_text,
                    expected_stdout=expected_stdout,
                    actual_stdout=execution.stdout,
                    stderr=execution.stderr,
                    exit_code=execution.exit_code,
                    elapsed_ms=execution.elapsed_ms,
                ),
                JudgeStatus.MLE,
            )

        if execution.internal_error:
            return (
                CaseResult(
                    status="ERROR",
                    stdin=stdin_text,
                    expected_stdout=expected_stdout,
                    actual_stdout=execution.stdout,
                    stderr=execution.internal_error if not execution.stderr else execution.stderr,
                    exit_code=execution.exit_code,
                    elapsed_ms=execution.elapsed_ms,
                ),
                JudgeStatus.INTERNAL_ERROR,
            )

        if execution.exit_code not in (None, 0):
            return (
                CaseResult(
                    status="ERROR",
                    stdin=stdin_text,
                    expected_stdout=expected_stdout,
                    actual_stdout=execution.stdout,
                    stderr=execution.stderr,
                    exit_code=execution.exit_code,
                    elapsed_ms=execution.elapsed_ms,
                ),
                JudgeStatus.RE,
            )

        expected_normalized = normalize_output(expected_stdout, level.judge_policy.output_normalization)
        actual_normalized = normalize_output(execution.stdout, level.judge_policy.output_normalization)

        if actual_normalized == expected_normalized:
            return (
                CaseResult(
                    status="PASS",
                    stdin=stdin_text,
                    expected_stdout=expected_stdout,
                    actual_stdout=execution.stdout,
                    stderr=execution.stderr,
                    exit_code=execution.exit_code,
                    elapsed_ms=execution.elapsed_ms,
                ),
                JudgeStatus.AC,
            )

        return (
            CaseResult(
                status="FAIL",
                stdin=stdin_text,
                expected_stdout=expected_stdout,
                actual_stdout=execution.stdout,
                stderr=execution.stderr,
                exit_code=execution.exit_code,
                elapsed_ms=execution.elapsed_ms,
            ),
            JudgeStatus.WA,
        )


def _summary_from_status(status: JudgeStatus, failed_case_index: int | None, executed: int, configured: int) -> str:
    if status is JudgeStatus.AC:
        return f"Accepted ({executed}/{configured} cases passed)."
    if status is JudgeStatus.WA:
        return f"Wrong answer at case {failed_case_index}."
    if status is JudgeStatus.TLE:
        return f"Time limit exceeded at case {failed_case_index}."
    if status is JudgeStatus.MLE:
        return f"Memory limit exceeded at case {failed_case_index}."
    if status is JudgeStatus.RE:
        return f"Runtime error at case {failed_case_index}."
    if status is JudgeStatus.INTERNAL_ERROR:
        return f"Internal error at case {failed_case_index}."
    return "Internal error."


def _sum_elapsed_ms(case_results: list[CaseResult]) -> int | None:
    values = [x.elapsed_ms for x in case_results if x.elapsed_ms is not None]
    if not values:
        return None
    return sum(values)


def _first_non_empty(values: list[str]) -> str:
    for x in values:
        if x:
            return x
    return ""

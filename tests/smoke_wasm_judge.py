from __future__ import annotations

from dataclasses import dataclass

from block2python.contracts import JudgePolicy, LevelSpec, OutputNormalization, Submission, Testcase
from block2python.judge.wasm_judge import WasmJudge
from block2python.judge.wasm_runner import ExecutionResult


@dataclass
class FakeRunner:
    scenario: str

    def execute(self, python_code: str, stdin_text: str, *, time_limit_ms: int) -> ExecutionResult:
        _ = (python_code, stdin_text, time_limit_ms)
        if self.scenario == "ac":
            return ExecutionResult(stdout="3\n", stderr="", exit_code=0, elapsed_ms=12)
        if self.scenario == "wa":
            return ExecutionResult(stdout="4\n", stderr="", exit_code=0, elapsed_ms=10)
        if self.scenario == "tle":
            return ExecutionResult(stdout="", stderr="", elapsed_ms=2001, timed_out=True)
        if self.scenario == "re":
            return ExecutionResult(stdout="", stderr="Traceback...", exit_code=1, elapsed_ms=6)
        return ExecutionResult(internal_error="runner setup failed", elapsed_ms=1)


def _level(expected_stdout: str = "3\n") -> LevelSpec:
    return LevelSpec(
        level_id="smoke",
        title="smoke",
        prompt="",
        testcases=(Testcase(stdin="1 2\n", expected_stdout=expected_stdout),),
        judge_policy=JudgePolicy(
            time_limit_ms=1500,
            output_normalization=OutputNormalization(
                strip_trailing_whitespace=True,
                normalize_newlines_to_lf=True,
                strip_trailing_newline=True,
            ),
        ),
    )


def _assert(label: str, cond: bool) -> None:
    if not cond:
        raise AssertionError(label)


def main() -> int:
    sub = Submission(level_id="smoke", python_code="print(1+2)")

    ac = WasmJudge(FakeRunner("ac")).judge(sub, _level())
    _assert("AC status", ac.status.value == "AC")

    wa = WasmJudge(FakeRunner("wa")).judge(sub, _level())
    _assert("WA status", wa.status.value == "WA")

    tle = WasmJudge(FakeRunner("tle")).judge(sub, _level())
    _assert("TLE status", tle.status.value == "TLE")

    re = WasmJudge(FakeRunner("re")).judge(sub, _level())
    _assert("RE status", re.status.value == "RE")

    internal = WasmJudge(FakeRunner("internal")).judge(sub, _level())
    _assert("INTERNAL_ERROR status", internal.status.value == "INTERNAL_ERROR")

    normalized = WasmJudge(FakeRunner("ac")).judge(sub, _level(expected_stdout="3\r\n"))
    _assert("normalization supports CRLF", normalized.status.value == "AC")

    print("smoke_wasm_judge: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

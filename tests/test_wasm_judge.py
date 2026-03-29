"""Tests for WasmJudge logic (with fake runner)."""

from __future__ import annotations

from dataclasses import dataclass

import pytest

from block2python.contracts import JudgePolicy, JudgeStatus, LevelSpec, OutputNormalization, Submission, Testcase as JudgeTestcase
from block2python.judge.wasm_judge import WasmJudge
from block2python.judge.wasm_runner import ExecutionResult


@dataclass
class FakeRunner:
    """Fake runner for testing judge logic without actual wasm execution."""

    scenario: str

    def execute(
        self,
        python_code: str,
        stdin_text: str,
        *,
        time_limit_ms: int,
        memory_limit_kb: int | None = None,
    ) -> ExecutionResult:
        _ = (python_code, stdin_text, time_limit_ms, memory_limit_kb)
        if self.scenario == "ac":
            return ExecutionResult(stdout="3\n", stderr="", exit_code=0, elapsed_ms=12)
        if self.scenario == "wa":
            return ExecutionResult(stdout="4\n", stderr="", exit_code=0, elapsed_ms=10)
        if self.scenario == "tle":
            return ExecutionResult(stdout="", stderr="", elapsed_ms=2001, timed_out=True)
        if self.scenario == "mle":
            return ExecutionResult(stdout="", stderr="memory limit exceeded", elapsed_ms=25, memory_exceeded=True)
        if self.scenario == "re":
            return ExecutionResult(stdout="", stderr="Traceback...", exit_code=1, elapsed_ms=6)
        return ExecutionResult(internal_error="runner setup failed", elapsed_ms=1)


@dataclass
class SpyRunner:
    calls: list[tuple[int, int | None]]

    def execute(
        self,
        python_code: str,
        stdin_text: str,
        *,
        time_limit_ms: int,
        memory_limit_kb: int | None = None,
    ) -> ExecutionResult:
        _ = (python_code, stdin_text)
        self.calls.append((time_limit_ms, memory_limit_kb))
        return ExecutionResult(stdout="3\n", stderr="", exit_code=0, elapsed_ms=5)


@pytest.fixture
def basic_level() -> LevelSpec:
    """Basic level spec with one testcase."""
    return LevelSpec(
        level_id="test",
        title="Test Level",
        prompt="",
        testcases=(JudgeTestcase(stdin="1 2\n", expected_stdout="3\n"),),
        judge_policy=JudgePolicy(
            time_limit_ms=1500,
            memory_limit_kb=65536,
            output_normalization=OutputNormalization(
                strip_trailing_whitespace=True,
                normalize_newlines_to_lf=True,
                strip_trailing_newline=True,
            ),
        ),
    )


@pytest.fixture
def basic_submission() -> Submission:
    """Basic submission."""
    return Submission(level_id="test", python_code="print(1+2)")


class TestWasmJudge:
    """Test WasmJudge status detection and result assembly."""

    def test_ac_status(self, basic_submission: Submission, basic_level: LevelSpec):
        judge = WasmJudge(FakeRunner("ac"))
        result = judge.judge(basic_submission, basic_level)
        assert result.status == JudgeStatus.AC
        assert len(result.case_results) == 1
        assert result.case_results[0].status == "PASS"
        assert result.failed_case_index is None

    def test_wa_status(self, basic_submission: Submission, basic_level: LevelSpec):
        judge = WasmJudge(FakeRunner("wa"))
        result = judge.judge(basic_submission, basic_level)
        assert result.status == JudgeStatus.WA
        assert result.failed_case_index == 0
        assert result.case_results[0].status == "FAIL"

    def test_tle_status(self, basic_submission: Submission, basic_level: LevelSpec):
        judge = WasmJudge(FakeRunner("tle"))
        result = judge.judge(basic_submission, basic_level)
        assert result.status == JudgeStatus.TLE
        assert result.failed_case_index == 0
        assert result.case_results[0].status == "TIMEOUT"

    def test_mle_status(self, basic_submission: Submission, basic_level: LevelSpec):
        judge = WasmJudge(FakeRunner("mle"))
        result = judge.judge(basic_submission, basic_level)
        assert result.status == JudgeStatus.MLE
        assert result.failed_case_index == 0
        assert result.case_results[0].status == "MEMORY_LIMIT"

    def test_re_status(self, basic_submission: Submission, basic_level: LevelSpec):
        judge = WasmJudge(FakeRunner("re"))
        result = judge.judge(basic_submission, basic_level)
        assert result.status == JudgeStatus.RE
        assert result.failed_case_index == 0
        assert result.case_results[0].status == "ERROR"

    def test_internal_error(self, basic_submission: Submission, basic_level: LevelSpec):
        judge = WasmJudge(FakeRunner("internal"))
        result = judge.judge(basic_submission, basic_level)
        assert result.status == JudgeStatus.INTERNAL_ERROR
        assert result.failed_case_index == 0

    def test_normalization_crlf(self, basic_submission: Submission):
        level = LevelSpec(
            level_id="test",
            title="Test",
            prompt="",
            testcases=(JudgeTestcase(stdin="", expected_stdout="3\r\n"),),
            judge_policy=JudgePolicy(
                time_limit_ms=1000,
                output_normalization=OutputNormalization(
                    strip_trailing_whitespace=True,
                    normalize_newlines_to_lf=True,
                    strip_trailing_newline=True,
                ),
            ),
        )
        judge = WasmJudge(FakeRunner("ac"))
        result = judge.judge(basic_submission, level)
        assert result.status == JudgeStatus.AC

    def test_no_testcases(self, basic_submission: Submission):
        level = LevelSpec(level_id="empty", title="Empty", prompt="", testcases=())
        judge = WasmJudge(FakeRunner("ac"))
        result = judge.judge(basic_submission, level)
        assert result.status == JudgeStatus.AC
        assert len(result.case_results) == 0

    def test_fail_fast_enabled(self, basic_submission: Submission):
        level = LevelSpec(
            level_id="multi",
            title="Multi",
            prompt="",
            testcases=(
                JudgeTestcase(stdin="", expected_stdout="3\n"),
                JudgeTestcase(stdin="", expected_stdout="5\n"),
            ),
        )
        judge = WasmJudge(FakeRunner("wa"), fail_fast=True)
        result = judge.judge(basic_submission, level)
        assert result.status == JudgeStatus.WA
        assert len(result.case_results) == 1  # Should stop after first failure

    def test_fail_fast_disabled(self, basic_submission: Submission):
        level = LevelSpec(
            level_id="multi",
            title="Multi",
            prompt="",
            testcases=(
                JudgeTestcase(stdin="", expected_stdout="3\n"),
                JudgeTestcase(stdin="", expected_stdout="5\n"),
            ),
        )
        judge = WasmJudge(FakeRunner("wa"), fail_fast=False)
        result = judge.judge(basic_submission, level)
        assert result.status == JudgeStatus.WA
        assert len(result.case_results) == 2  # Should run all cases

    def test_elapsed_ms_aggregation(self, basic_submission: Submission, basic_level: LevelSpec):
        judge = WasmJudge(FakeRunner("ac"))
        result = judge.judge(basic_submission, basic_level)
        assert result.elapsed_ms == 12

    def test_warmup_runs_once_without_memory_limit(self, basic_submission: Submission, basic_level: LevelSpec):
        calls: list[tuple[int, int | None]] = []
        judge = WasmJudge(SpyRunner(calls))

        first_result = judge.judge(basic_submission, basic_level)
        second_result = judge.judge(basic_submission, basic_level)

        assert first_result.status == JudgeStatus.AC
        assert second_result.status == JudgeStatus.AC

        # First invocation: warmup + one testcase execution
        # Second invocation: one testcase execution only (warmup already done)
        assert len(calls) == 3
        assert calls[0][1] is None
        assert calls[1][1] == basic_level.judge_policy.memory_limit_kb
        assert calls[2][1] == basic_level.judge_policy.memory_limit_kb

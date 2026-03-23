"""Smoke tests for real WasmJudge execution with wasmtime + python.wasm."""

from __future__ import annotations

import os
import shutil
from dataclasses import replace
from pathlib import Path

import pytest

from block2python.content import load_levels
from block2python.contracts import (
    JudgePolicy,
    JudgeStatus,
    LevelSpec,
    OutputNormalization,
    Submission,
    Testcase as JudgeTestcase,
)
from block2python.judge.wasm_judge import WasmJudge
from block2python.judge.wasm_runner import WasmtimeRunner


@pytest.fixture(scope="module")
def wasm_available() -> Path:
    if not shutil.which("wasmtime"):
        pytest.skip("wasmtime not found in PATH")
    wasm_path = Path("assets/wasm/python.wasm")
    if not wasm_path.exists():
        pytest.skip(f"python.wasm not found at {wasm_path}")
    return wasm_path


@pytest.fixture
def wasm_runner(wasm_available: Path) -> WasmtimeRunner:
    code_mode = os.environ.get("BLOCK2PYTHON_WASM_CODE_MODE", "auto")
    return WasmtimeRunner(wasm_path=wasm_available, code_mode=code_mode)


@pytest.fixture
def wasm_judge(wasm_runner: WasmtimeRunner) -> WasmJudge:
    return WasmJudge(runner=wasm_runner, fail_fast=True)


@pytest.mark.requires_wasm
class TestWasmJudgeSmoke:
    def test_basic_ac(self, wasm_judge: WasmJudge):
        level = LevelSpec(
            level_id="smoke-ac",
            title="Smoke Test AC",
            testcases=(JudgeTestcase(stdin="5\n", expected_stdout="5\n"),),
            judge_policy=JudgePolicy(time_limit_ms=2000, memory_limit_kb=256 * 1024),
        )
        submission = Submission(level_id="smoke-ac", python_code="print(input())")
        result = wasm_judge.judge(submission, level)

        assert result.status == JudgeStatus.AC
        assert result.case_results[0].status == "PASS"

    def test_basic_wa(self, wasm_judge: WasmJudge):
        level = LevelSpec(
            level_id="smoke-wa",
            title="Smoke Test WA",
            testcases=(JudgeTestcase(stdin="5\n", expected_stdout="10\n"),),
            judge_policy=JudgePolicy(time_limit_ms=2000, memory_limit_kb=256 * 1024),
        )
        submission = Submission(level_id="smoke-wa", python_code="print(input())")
        result = wasm_judge.judge(submission, level)

        assert result.status == JudgeStatus.WA
        assert result.case_results[0].status == "FAIL"

    def test_tle(self, wasm_judge: WasmJudge):
        level = LevelSpec(
            level_id="smoke-tle",
            title="Smoke Test TLE",
            testcases=(JudgeTestcase(stdin="", expected_stdout="done\n"),),
            judge_policy=JudgePolicy(time_limit_ms=500, memory_limit_kb=256 * 1024),
        )
        submission = Submission(level_id="smoke-tle", python_code="while True: pass")
        result = wasm_judge.judge(submission, level)

        assert result.status == JudgeStatus.TLE
        assert result.case_results[0].status == "TIMEOUT"

    def test_output_normalization(self, wasm_judge: WasmJudge):
        level = LevelSpec(
            level_id="smoke-normalize",
            title="Output Normalization",
            testcases=(JudgeTestcase(stdin="", expected_stdout="hello\n"),),
            judge_policy=JudgePolicy(
                time_limit_ms=2000,
                output_normalization=OutputNormalization(
                    strip_trailing_whitespace=True,
                    normalize_newlines_to_lf=True,
                ),
            ),
        )
        submission = Submission(level_id="smoke-normalize", python_code="print('hello  ')")
        result = wasm_judge.judge(submission, level)

        assert result.status == JudgeStatus.AC


@pytest.mark.requires_wasm
@pytest.mark.integration
class TestWasmJudgeYAMLLevels:
    def test_load_and_judge_benchmark_level(self, wasm_judge: WasmJudge):
        levels = load_levels(Path("assets/levels"))
        level = levels.get("judge-precision-sum-series")
        if level is None:
            pytest.skip("judge-precision-sum-series level id not found")

        # On some Windows hosts the wasm Python runtime needs a higher memory cap.
        level = replace(
            level,
            judge_policy=replace(level.judge_policy, memory_limit_kb=max(level.judge_policy.memory_limit_kb or 0, 256 * 1024)),
        )

        submission = Submission(
            level_id=level.level_id,
            python_code=(
                "import sys\n"
                "n = int(sys.stdin.readline().strip())\n"
                "total = 0\n"
                "for i in range(1, n + 1):\n"
                "    total += i * i\n"
                "print(total)\n"
            ),
        )
        result = wasm_judge.judge(submission, level)

        assert result.status == JudgeStatus.AC
        assert all(case.status == "PASS" for case in result.case_results)

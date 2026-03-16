"""Smoke tests for real WasmJudge execution with wasmtime + python.wasm."""

from __future__ import annotations

import os
import shutil
from pathlib import Path

import pytest

from block2python.app.levels_loader import load_levels
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
<<<<<<< HEAD
    def test_load_and_judge_add_two_numbers(self, wasm_judge: WasmJudge):
        levels = load_levels(Path("assets/levels"))
        level = levels.get("add-two-numbers")
        if level is None:
            pytest.skip("add-two-numbers level id not found")

        submission = Submission(
            level_id=level.level_id,
            python_code="a, b = map(int, input().split())\nprint(a + b)",
=======
    def test_load_and_judge_demo_basic_io_hello(self, wasm_judge: WasmJudge):
        levels = load_levels(Path("assets/levels"))
        level = levels.get("demo-basic-io-hello")
        if level is None:
            pytest.skip("demo-basic-io-hello level id not found")

        submission = Submission(
            level_id=level.level_id,
            python_code="name = input()\nprint('Hello, ' + name)",
>>>>>>> main
        )
        result = wasm_judge.judge(submission, level)

        assert result.status == JudgeStatus.AC
        assert all(case.status == "PASS" for case in result.case_results)

<<<<<<< HEAD
    def test_load_and_judge_fizzbuzz_simple(self, wasm_judge: WasmJudge):
        levels = load_levels(Path("assets/levels"))
        level = levels.get("fizzbuzz-simple")
        if level is None:
            pytest.skip("fizzbuzz-simple level id not found")

        submission = Submission(
            level_id=level.level_id,
            python_code=(
                "n = int(input())\n"
                "if n % 15 == 0:\n"
                "    print('FizzBuzz')\n"
                "elif n % 3 == 0:\n"
                "    print('Fizz')\n"
                "elif n % 5 == 0:\n"
                "    print('Buzz')\n"
                "else:\n"
                "    print(n)\n"
            ),
=======
    def test_load_and_judge_practice_basic_io_sum(self, wasm_judge: WasmJudge):
        levels = load_levels(Path("assets/levels"))
        level = levels.get("practice-basic-io-sum")
        if level is None:
            pytest.skip("practice-basic-io-sum level id not found")

        submission = Submission(
            level_id=level.level_id,
            python_code="a = int(input())\nb = int(input())\nprint(a + b)",
>>>>>>> main
        )
        result = wasm_judge.judge(submission, level)

        assert result.status == JudgeStatus.AC
        assert all(case.status == "PASS" for case in result.case_results)

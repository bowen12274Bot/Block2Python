#!/usr/bin/env python3
from __future__ import annotations

import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TESTS_DIR = ROOT / "tests"
PROBLEM = ROOT.name


def solve(problem: str, raw_input: str) -> str:
    lines = raw_input.strip("\n").splitlines()
    if problem == "ai-track-input-gate":
        name = lines[0].strip()
        return f"Hello, {name}!\n"
    if problem == "ai-track-variable-base":
        a, b = map(int, lines[0].split())
        return f"sum={a+b}\ndiff={a-b}\n"
    if problem == "ai-track-if-canyon":
        score = int(lines[0])
        return ("PASS\n" if score >= 60 else "FAIL\n")
    if problem == "ai-track-loop-lab":
        n = int(lines[0])
        return f"{n * (n + 1) // 2}\n"
    if problem == "ai-track-bug-king-castle":
        n = int(lines[0])
        arr = list(map(int, lines[1].split()))
        assert len(arr) == n
        cnt = sum(1 for x in arr if x >= 0)
        total = sum(arr)
        return f"{cnt} {total}\n"
    raise ValueError(problem)


def write_case(path_base: Path, inp: str) -> None:
    path_base.parent.mkdir(parents=True, exist_ok=True)
    path_base.with_suffix(".in").write_text(inp, encoding="utf-8")
    path_base.with_suffix(".ans").write_text(solve(PROBLEM, inp), encoding="utf-8")


def generate() -> None:
    random.seed(20260326)

    if PROBLEM == "ai-track-input-gate":
        write_case(TESTS_DIR / "samples" / "sample1", "Alice\n")
        for i, name in enumerate(["Bob", "Byte", "Coder", "Python"], 1):
            write_case(TESTS_DIR / "system" / f"s{i:02d}", f"{name}\n")

    elif PROBLEM == "ai-track-variable-base":
        write_case(TESTS_DIR / "samples" / "sample1", "8 3\n")
        for i, (a, b) in enumerate([(0, 0), (-2, 7), (100, -99), (-55, -45)], 1):
            write_case(TESTS_DIR / "system" / f"s{i:02d}", f"{a} {b}\n")

    elif PROBLEM == "ai-track-if-canyon":
        write_case(TESTS_DIR / "samples" / "sample1", "60\n")
        for i, score in enumerate([0, 59, 61, 100], 1):
            write_case(TESTS_DIR / "system" / f"s{i:02d}", f"{score}\n")

    elif PROBLEM == "ai-track-loop-lab":
        write_case(TESTS_DIR / "samples" / "sample1", "5\n")
        for i, n in enumerate([1, 2, 100, 99999], 1):
            write_case(TESTS_DIR / "system" / f"s{i:02d}", f"{n}\n")

    elif PROBLEM == "ai-track-bug-king-castle":
        write_case(TESTS_DIR / "samples" / "sample1", "5\n-1 0 2 -3 4\n")
        cases = [
            [10, -10, 5, -5, 0, 1],
            [-1, -2, -3, -4],
            [0, 0, 0],
            [7, 8, 9, -20, 1],
        ]
        for i, arr in enumerate(cases, 1):
            write_case(TESTS_DIR / "system" / f"s{i:02d}", f"{len(arr)}\n{' '.join(map(str, arr))}\n")


def main() -> int:
    generate()
    print(f"Generated tests for {PROBLEM}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

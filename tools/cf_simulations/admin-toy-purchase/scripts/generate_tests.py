#!/usr/bin/env python3
from __future__ import annotations

import random
from bisect import bisect_right
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TESTS_DIR = ROOT / "tests"


def count_subsets(values: list[int], limit: int) -> int:
    n = len(values)
    m = n // 2
    left = values[:m]
    right = values[m:]

    left_sums = []
    for mask in range(1 << len(left)):
        s = 0
        for i, v in enumerate(left):
            if mask & (1 << i):
                s += v
        if s <= limit:
            left_sums.append(s)

    right_sums = []
    for mask in range(1 << len(right)):
        s = 0
        for i, v in enumerate(right):
            if mask & (1 << i):
                s += v
        if s <= limit:
            right_sums.append(s)

    right_sums.sort()

    total = 0
    for ls in left_sums:
        total += bisect_right(right_sums, limit - ls)
    return total


def write_case(path_base: Path, n: int, x: int, arr: list[int]) -> None:
    path_base.parent.mkdir(parents=True, exist_ok=True)
    input_text = f"{n} {x}\n" + " ".join(map(str, arr)) + "\n"
    answer_text = f"{count_subsets(arr, x)}\n"
    path_base.with_suffix(".in").write_text(input_text, encoding="utf-8")
    path_base.with_suffix(".ans").write_text(answer_text, encoding="utf-8")


def main() -> int:
    random.seed(20260320)

    # sample
    write_case(
        TESTS_DIR / "samples" / "sample1",
        5,
        600,
        [20, 30, 50, 100, 10],
    )

    # edge / adversarial pretests
    write_case(TESTS_DIR / "pretests" / "p01_min", 1, 1, [1])
    write_case(TESTS_DIR / "pretests" / "p02_single_fail", 1, 5, [10])
    write_case(TESTS_DIR / "pretests" / "p03_all_ones", 30, 15, [1] * 30)
    write_case(TESTS_DIR / "pretests" / "p04_all_big", 30, 500000, [100000] * 30)
    write_case(
        TESTS_DIR / "pretests" / "p05_mixed_boundary",
        30,
        500000,
        [1, 100000] * 15,
    )

    # system random tests
    for i in range(1, 26):
        n = random.randint(1, 30)
        x = random.randint(1, 500000)
        mode = random.choice(["uniform", "small", "large", "spiky"])
        if mode == "uniform":
            arr = [random.randint(1, 100000) for _ in range(n)]
        elif mode == "small":
            arr = [random.randint(1, 100) for _ in range(n)]
        elif mode == "large":
            arr = [random.randint(90000, 100000) for _ in range(n)]
        else:
            arr = [1 if random.random() < 0.5 else 100000 for _ in range(n)]

        write_case(TESTS_DIR / "system" / f"s{i:02d}", n, x, arr)

    print("Generated tests with deterministic seed: 20260320")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

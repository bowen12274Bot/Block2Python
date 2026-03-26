#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def compile_cpp(src: Path, out: Path) -> None:
    cmd = ["g++.exe", "-O2", "-std=c++17", str(src), "-o", str(out)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(
            f"Compile failed: {src}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )


def run_case(exe: Path, case_in: Path, expected: str) -> tuple[bool, str]:
    inp = case_in.read_text(encoding="utf-8")
    proc = subprocess.run(
        [str(exe)],
        input=inp,
        text=True,
        capture_output=True,
    )
    out = proc.stdout.strip()
    if proc.returncode != 0:
        return False, f"RTE (code {proc.returncode}) stderr={proc.stderr.strip()}"
    if out != expected.strip():
        return False, f"WA expected={expected.strip()} got={out}"
    return True, "AC"


def collect_cases() -> list[Path]:
    tests_dir = ROOT / "tests"
    return sorted(tests_dir.glob("**/*.in"))


def judge_solution(exe: Path) -> tuple[int, int, list[str]]:
    cases = collect_cases()
    passed = 0
    details: list[str] = []
    for case_in in cases:
        case_ans = case_in.with_suffix(".ans")
        expected = case_ans.read_text(encoding="utf-8")
        ok, msg = run_case(exe, case_in, expected)
        tag = "PASS" if ok else "FAIL"
        details.append(f"[{tag}] {case_in.relative_to(ROOT)} -> {msg}")
        if ok:
            passed += 1
    return passed, len(cases), details


def main() -> int:
    parser = argparse.ArgumentParser(description="Compile and judge C++ solutions")
    parser.add_argument(
        "--target",
        required=True,
        help="Path to C++ source file relative to problem root",
    )
    args = parser.parse_args()

    src = (ROOT / args.target).resolve()
    if not src.exists():
        raise FileNotFoundError(f"Source not found: {src}")

    ascii_base = Path("C:/Temp/cfjudge_build")
    ascii_base.mkdir(parents=True, exist_ok=True)
    work_dir = Path(tempfile.mkdtemp(prefix="run_", dir=str(ascii_base)))

    src_copy = work_dir / src.name
    exe = work_dir / (src.stem + ".exe")
    shutil.copy2(src, src_copy)

    compile_cpp(src_copy, exe)
    passed, total, details = judge_solution(exe)

    for line in details:
        print(line)
    print(f"Summary: {passed}/{total} passed")

    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main())

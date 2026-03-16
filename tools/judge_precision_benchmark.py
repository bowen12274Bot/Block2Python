from __future__ import annotations

import argparse
import json
import statistics
import sys
import time
from collections import Counter
from dataclasses import replace
from pathlib import Path

import psutil
import yaml

from block2python.contracts import JudgePolicy, JudgeStatus, LevelSpec, Submission, Testcase
from block2python.judge import WasmJudge, WasmtimeRunner


def _percentile(values: list[int], p: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    if len(ordered) == 1:
        return float(ordered[0])
    rank = (len(ordered) - 1) * p
    low = int(rank)
    high = min(low + 1, len(ordered) - 1)
    frac = rank - low
    return ordered[low] + (ordered[high] - ordered[low]) * frac


def _load_level(level_file: Path) -> LevelSpec:
    payload = yaml.safe_load(level_file.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"Invalid YAML object: {level_file}")

    level_id = str(payload.get("level_id", "")).strip()
    title = str(payload.get("title", "")).strip()
    if not level_id or not title:
        raise ValueError("level_id/title is required")

    testcases_raw = payload.get("testcases", [])
    if not isinstance(testcases_raw, list) or not testcases_raw:
        raise ValueError("At least one testcase is required")

    testcases: list[Testcase] = []
    for item in testcases_raw:
        if not isinstance(item, dict):
            continue
        if "stdin" not in item or "expected_stdout" not in item:
            continue
        testcases.append(
            Testcase(
                name=str(item.get("name") or "") or None,
                stdin=str(item.get("stdin", "")),
                expected_stdout=str(item.get("expected_stdout", "")),
            )
        )

    if not testcases:
        raise ValueError("No valid inline testcases found")

    judge_policy_raw = payload.get("judge_policy") or {}
    if not isinstance(judge_policy_raw, dict):
        judge_policy_raw = {}

    tl = int(judge_policy_raw.get("time_limit_ms", 1200))
    mem_mb = judge_policy_raw.get("memory_limit_mb")
    mem_kb = None if mem_mb is None else int(mem_mb) * 1024

    return LevelSpec(
        level_id=level_id,
        title=title,
        prompt=str(payload.get("prompt", "")),
        learning_markdown=str(payload.get("learning_markdown", "")),
        testcases=tuple(testcases),
        judge_policy=JudgePolicy(time_limit_ms=max(1, tl), memory_limit_kb=mem_kb),
        metadata=payload.get("metadata") if isinstance(payload.get("metadata"), dict) else {},
    )


def _build_passing_submission(level_id: str) -> Submission:
    return Submission(
        level_id=level_id,
        python_code=(
            "import sys\n"
            "n = int(sys.stdin.readline().strip())\n"
            "total = 0\n"
            "for i in range(1, n + 1):\n"
            "    total += i * i\n"
            "print(total)\n"
        ),
    )


def _build_tle_submission(level_id: str) -> Submission:
    return Submission(
        level_id=level_id,
        python_code="import time\nwhile True:\n    time.sleep(0.01)\n",
    )


def _build_memory_submission(level_id: str) -> Submission:
    return Submission(
        level_id=level_id,
        python_code="data = [0] * (128 * 1024 * 1024 // 8)\nprint('ok')\n",
    )


def run_benchmark(args: argparse.Namespace) -> dict[str, object]:
    level = _load_level(args.level_file)
    tuned_memory_kb = max(level.judge_policy.memory_limit_kb or 0, args.precision_memory_limit_mb * 1024)
    level = replace(level, judge_policy=replace(level.judge_policy, memory_limit_kb=tuned_memory_kb))
    submission = _build_passing_submission(level.level_id)

    runner = WasmtimeRunner(
        wasm_path=args.wasm_path,
        wasmtime_bin=args.wasmtime_bin,
        code_mode=args.code_mode,
    )
    judge = WasmJudge(runner=runner, fail_fast=True)

    process = psutil.Process()
    statuses: list[str] = []
    elapsed_list: list[int] = []
    rss_mb_list: list[float] = []
    rss_delta_mb_list: list[float] = []

    for _ in range(args.runs):
        rss_before = process.memory_info().rss / (1024 * 1024)
        started = time.perf_counter()
        result = judge.judge(submission, level)
        elapsed_fallback_ms = int((time.perf_counter() - started) * 1000)
        elapsed_ms = result.elapsed_ms if result.elapsed_ms is not None else elapsed_fallback_ms
        rss_after = process.memory_info().rss / (1024 * 1024)

        statuses.append(result.status.value)
        elapsed_list.append(int(elapsed_ms))
        rss_mb_list.append(rss_after)
        rss_delta_mb_list.append(rss_after - rss_before)

    status_counter = Counter(statuses)
    ac_count = status_counter.get(JudgeStatus.AC.value, 0)
    ac_rate = ac_count / max(1, args.runs)

    slow_count = sum(1 for x in elapsed_list if x > args.warn_elapsed_ms)

    # Guard checks for sandbox behavior.
    tle_level = replace(
        level,
        judge_policy=replace(level.judge_policy, time_limit_ms=500, memory_limit_kb=tuned_memory_kb),
    )
    tle_result = judge.judge(_build_tle_submission(level.level_id), tle_level)

    mem_limit_kb = max(8 * 1024, args.memory_probe_limit_mb * 1024)
    memory_level = replace(
        level,
        judge_policy=replace(level.judge_policy, time_limit_ms=2500, memory_limit_kb=mem_limit_kb),
    )
    memory_result = judge.judge(_build_memory_submission(level.level_id), memory_level)

    summary = {
        "level_id": level.level_id,
        "runs": args.runs,
        "status_counts": dict(status_counter),
        "ac_rate": ac_rate,
        "precision_ok": ac_count == args.runs,
        "elapsed_ms": {
            "min": min(elapsed_list) if elapsed_list else 0,
            "mean": statistics.fmean(elapsed_list) if elapsed_list else 0.0,
            "p50": _percentile(elapsed_list, 0.50),
            "p95": _percentile(elapsed_list, 0.95),
            "max": max(elapsed_list) if elapsed_list else 0,
            "warn_threshold": args.warn_elapsed_ms,
            "slow_count": slow_count,
        },
        "memory_mb": {
            "start": rss_mb_list[0] if rss_mb_list else 0.0,
            "end": rss_mb_list[-1] if rss_mb_list else 0.0,
            "peak": max(rss_mb_list) if rss_mb_list else 0.0,
            "growth": (rss_mb_list[-1] - rss_mb_list[0]) if len(rss_mb_list) >= 2 else 0.0,
            "max_single_run_delta": max(rss_delta_mb_list) if rss_delta_mb_list else 0.0,
        },
        "sandbox_guards": {
            "tle_status": tle_result.status.value,
            "tle_ok": tle_result.status is JudgeStatus.TLE,
            "memory_probe_status": memory_result.status.value,
            "memory_probe_ok": memory_result.status in (JudgeStatus.MLE, JudgeStatus.RE),
            "memory_probe_limit_mb": args.memory_probe_limit_mb,
            "precision_memory_limit_mb": args.precision_memory_limit_mb,
        },
    }

    return summary


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Benchmark wasm judge precision, latency and memory behavior.")
    parser.add_argument("--runs", type=int, default=30, help="How many AC benchmark runs to execute.")
    parser.add_argument("--warn-elapsed-ms", type=int, default=1800, help="Warn threshold for per-run elapsed ms.")
    parser.add_argument("--code-mode", choices=["auto", "inline", "tempfile", "stdin"], default="auto")
    parser.add_argument("--wasmtime-bin", default="wasmtime")
    parser.add_argument("--memory-probe-limit-mb", type=int, default=16)
    parser.add_argument("--precision-memory-limit-mb", type=int, default=256)
    parser.add_argument(
        "--level-file",
        type=Path,
        default=Path("assets/levels/judge-precision-sum-series.yaml"),
    )
    parser.add_argument("--wasm-path", type=Path, default=Path("assets/wasm/python.wasm"))
    parser.add_argument("--output-json", type=Path, default=None)
    parser.add_argument("--strict", action="store_true", help="Exit non-zero when benchmark checks fail.")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()

    if args.runs <= 0:
        print("runs must be > 0", file=sys.stderr)
        return 2

    if not args.level_file.exists():
        print(f"level file not found: {args.level_file}", file=sys.stderr)
        return 2

    if not args.wasm_path.exists():
        print(f"wasm file not found: {args.wasm_path}", file=sys.stderr)
        return 2

    report = run_benchmark(args)

    print("=== Judge Precision Benchmark ===")
    print(json.dumps(report, ensure_ascii=True, indent=2))

    if args.output_json is not None:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
        print(f"Report written to: {args.output_json}")

    precision_ok = bool(report.get("precision_ok"))
    tle_ok = bool(report.get("sandbox_guards", {}).get("tle_ok"))
    mem_ok = bool(report.get("sandbox_guards", {}).get("memory_probe_ok"))

    if args.strict and not (precision_ok and tle_ok and mem_ok):
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

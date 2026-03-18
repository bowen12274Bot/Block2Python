from __future__ import annotations

import os
from pathlib import Path

from block2python.judge import Judge, StubJudge, WasmJudge, WasmtimeRunner


class JudgeBuildError(Exception):
    pass


def build_judge_from_env() -> tuple[Judge, str]:
    """
    Build judge based on env vars.

    Supported modes:
      - BLOCK2PYTHON_JUDGE_MODE=auto|stub|wasm (default: auto)
      - BLOCK2PYTHON_WASM_PATH=<path to python.wasm>
      - BLOCK2PYTHON_WASMTIME_BIN=<wasmtime executable> (default: wasmtime)
      - BLOCK2PYTHON_WASM_CODE_MODE=auto|inline|tempfile|stdin (default: auto)
      - BLOCK2PYTHON_JUDGE_FAIL_FAST=true|false (default: true)
    """

    mode = os.environ.get("BLOCK2PYTHON_JUDGE_MODE", "auto").strip().lower()
    fail_fast = _parse_bool(os.environ.get("BLOCK2PYTHON_JUDGE_FAIL_FAST", "true"), default=True)

    if mode == "stub":
        return StubJudge(), "judge=StubJudge (forced by BLOCK2PYTHON_JUDGE_MODE=stub)"

    wasm_path = Path(os.environ.get("BLOCK2PYTHON_WASM_PATH", "assets/wasm/python.wasm"))
    wasmtime_bin = os.environ.get("BLOCK2PYTHON_WASMTIME_BIN", "wasmtime").strip() or "wasmtime"
    code_mode = os.environ.get("BLOCK2PYTHON_WASM_CODE_MODE", "auto").strip().lower() or "auto"

    if mode == "wasm":
        judge = WasmJudge(
            runner=WasmtimeRunner(wasm_path=wasm_path, wasmtime_bin=wasmtime_bin, code_mode=code_mode),
            fail_fast=fail_fast,
        )
        return judge, f"judge=WasmJudge wasm={wasm_path} wasmtime={wasmtime_bin} code_mode={code_mode}"

    if mode == "auto":
        if wasm_path.exists():
            judge = WasmJudge(
                runner=WasmtimeRunner(wasm_path=wasm_path, wasmtime_bin=wasmtime_bin, code_mode=code_mode),
                fail_fast=fail_fast,
            )
            return judge, f"judge=WasmJudge(auto) wasm={wasm_path} wasmtime={wasmtime_bin} code_mode={code_mode}"
        return StubJudge(), f"judge=StubJudge(auto fallback; wasm not found: {wasm_path})"

    raise JudgeBuildError(f"Unsupported BLOCK2PYTHON_JUDGE_MODE: {mode}")


def _parse_bool(raw: str, *, default: bool) -> bool:
    text = (raw or "").strip().lower()
    if text in {"1", "true", "yes", "on"}:
        return True
    if text in {"0", "false", "no", "off"}:
        return False
    return default

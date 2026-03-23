from __future__ import annotations

import os
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Literal, Protocol

from .process_monitor import monitor_process
from .wasm_launch import prepare_launch, resolve_code_modes, should_fallback_to_next


@dataclass(frozen=True, slots=True)
class ExecutionResult:
    stdout: str = ""
    stderr: str = ""
    exit_code: int | None = None
    elapsed_ms: int | None = None
    timed_out: bool = False
    memory_exceeded: bool = False
    internal_error: str | None = None


class WasmRunner(Protocol):
    def execute(
        self,
        python_code: str,
        stdin_text: str,
        *,
        time_limit_ms: int,
        memory_limit_kb: int | None = None,
    ) -> ExecutionResult:
        ...


class WasmtimeRunner:
    """Execute python.wasm via wasmtime CLI in a minimal WASI sandbox."""

    def __init__(
        self,
        wasm_path: Path,
        *,
        wasmtime_bin: str = "wasmtime",
        python_argv: tuple[str, ...] = (),
        preopen_dirs: tuple[Path, ...] = (),
        code_mode: Literal["auto", "inline", "tempfile", "stdin"] = "auto",
    ) -> None:
        self._wasm_path = wasm_path
        self._wasmtime_bin = wasmtime_bin
        self._python_argv = python_argv
        self._preopen_dirs = preopen_dirs
        self._code_mode = code_mode

    def execute(
        self,
        python_code: str,
        stdin_text: str,
        *,
        time_limit_ms: int,
        memory_limit_kb: int | None = None,
    ) -> ExecutionResult:
        if not self._wasm_path.exists():
            return ExecutionResult(internal_error=f"python.wasm not found: {self._wasm_path}")

        timeout_sec = max(1, time_limit_ms) / 1000.0
        last_result = ExecutionResult(internal_error="no execution strategy succeeded")
        for strategy in resolve_code_modes(self._code_mode):
            launch = prepare_launch(
                strategy,
                wasmtime_bin=self._wasmtime_bin,
                preopen_dirs=self._preopen_dirs,
                wasm_path=self._wasm_path,
                python_argv=self._python_argv,
                python_code=python_code,
                stdin_text=stdin_text,
            )
            try:
                result = self._run_once(
                    launch.command,
                    launch.process_stdin,
                    timeout_sec=timeout_sec,
                    memory_limit_kb=memory_limit_kb,
                    env_overrides=launch.env_overrides,
                )
            finally:
                launch.cleanup()

            if not should_fallback_to_next(strategy, result):
                return result
            last_result = result
        return last_result

    def _run_once(
        self,
        cmd: list[str],
        stdin_text: str,
        *,
        timeout_sec: float,
        memory_limit_kb: int | None,
        env_overrides: dict[str, str] | None = None,
    ) -> ExecutionResult:
        started = time.perf_counter()
        env = os.environ.copy()
        if env_overrides:
            env.update(env_overrides)

        try:
            process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env=env,
            )
        except FileNotFoundError:
            elapsed_ms = int((time.perf_counter() - started) * 1000)
            return ExecutionResult(
                stderr="",
                elapsed_ms=elapsed_ms,
                internal_error=f"wasmtime binary not found: {self._wasmtime_bin}",
            )
        except Exception as e:  # noqa: BLE001
            elapsed_ms = int((time.perf_counter() - started) * 1000)
            return ExecutionResult(elapsed_ms=elapsed_ms, internal_error=f"runner failure: {e}")

        return monitor_process(
            ExecutionResult,
            process,
            stdin_text,
            started=started,
            timeout_sec=timeout_sec,
            memory_limit_kb=memory_limit_kb,
        )

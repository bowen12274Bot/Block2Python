from __future__ import annotations

import base64
import os
import shlex
import subprocess
import tempfile
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Literal, Protocol


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
        for strategy in _resolve_code_modes(self._code_mode):
            launch = self._prepare_launch(strategy, python_code, stdin_text)
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

            if not _should_fallback_to_next(strategy, result):
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

        return _monitor_process(
            process,
            stdin_text,
            started=started,
            timeout_sec=timeout_sec,
            memory_limit_kb=memory_limit_kb,
        )

    def _build_base_command(self) -> list[str]:
        cmd = [self._wasmtime_bin, "run"]
        for d in self._preopen_dirs:
            cmd.extend(["--dir", str(d)])
        return cmd

    def _prepare_launch(self, strategy: str, python_code: str, stdin_text: str) -> "_LaunchConfig":
        base_cmd = self._build_base_command()
        if strategy == "inline":
            cmd = self._build_python_args(base_cmd, python_code)
            return _LaunchConfig(command=cmd, process_stdin=stdin_text)

        if strategy == "tempfile":
            tempdir = tempfile.TemporaryDirectory(prefix="b2p_wasm_")
            host_dir = Path(tempdir.name)
            guest_dir = "/sandbox"
            script_name = "submission.py"
            script_host_path = host_dir / script_name
            script_host_path.write_text(python_code, encoding="utf-8")

            cmd = list(base_cmd)
            cmd.extend(["--dir", f"{host_dir}::{guest_dir}"])
            cmd.append(str(self._wasm_path))
            cmd.append("--")
            cmd.append(f"{guest_dir}/{script_name}")
            return _LaunchConfig(
                command=cmd,
                process_stdin=stdin_text,
                cleanup=tempdir.cleanup,
            )

        # stdin strategy: Python reads script from stdin (`-`), while testcase input
        # is injected through an environment variable and restored as sys.stdin.
        wrapped = _build_stdin_wrapper(python_code)
        stdin_b64 = base64.b64encode(stdin_text.encode("utf-8")).decode("ascii")
        cmd = list(base_cmd)
        cmd.extend(["--env", f"BLOCK2PYTHON_STDIN_B64={stdin_b64}"])
        cmd.append(str(self._wasm_path))
        cmd.append("--")
        cmd.append("-")
        return _LaunchConfig(command=cmd, process_stdin=wrapped)

    def _build_python_args(self, base_cmd: list[str], python_code: str) -> list[str]:
        cmd = list(base_cmd)
        cmd.append(str(self._wasm_path))
        cmd.append("--")
        if not self._python_argv:
            cmd.extend(["-c", python_code])
            return cmd
        for arg in self._python_argv:
            if arg == "{code}":
                cmd.append(python_code)
            else:
                cmd.extend(shlex.split(arg) if " " in arg else [arg])
        return cmd


@dataclass(slots=True)
class _LaunchConfig:
    command: list[str]
    process_stdin: str
    env_overrides: dict[str, str] | None = None
    cleanup: Callable[[], None] = lambda: None


def _resolve_code_modes(code_mode: str) -> tuple[str, ...]:
    mode = code_mode.strip().lower()
    if mode == "inline":
        return ("inline",)
    if mode == "tempfile":
        return ("tempfile",)
    if mode == "stdin":
        return ("stdin",)
    # auto: keep old behavior first, then Windows-safe fallbacks.
    return ("inline", "tempfile", "stdin")


def _should_fallback_to_next(strategy: str, result: ExecutionResult) -> bool:
    if result.internal_error:
        return False
    if result.timed_out or result.memory_exceeded:
        return False
    if result.exit_code == 0:
        return False
    stderr = (result.stderr or "").lower()
    if strategy == "inline" and "can't open file '//-c'" in stderr:
        return True
    if strategy == "tempfile" and "no such file or directory" in stderr and "/sandbox/" in stderr:
        return True
    return False


def _build_stdin_wrapper(python_code: str) -> str:
    code_b64 = base64.b64encode(python_code.encode("utf-8")).decode("ascii")
    # Keep wrapper compact and deterministic for easier debugging.
    return (
        "import base64,io,os,sys\n"
        "sys.stdin=io.StringIO(base64.b64decode(os.environ.get('BLOCK2PYTHON_STDIN_B64','')).decode('utf-8','replace'))\n"
        f"exec(compile(base64.b64decode('{code_b64}').decode('utf-8','replace'),'<submission>','exec'))\n"
    )


def _coerce_text(value: str | bytes | None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def _monitor_process(
    process: subprocess.Popen[str],
    stdin_text: str,
    *,
    started: float,
    timeout_sec: float,
    memory_limit_kb: int | None,
) -> ExecutionResult:
    output: dict[str, str | int | None] = {"stdout": "", "stderr": "", "exit_code": None}
    failure: BaseException | None = None

    def _communicate() -> None:
        nonlocal failure
        try:
            stdout, stderr = process.communicate(input=stdin_text)
            output["stdout"] = stdout
            output["stderr"] = stderr
            output["exit_code"] = process.returncode
        except BaseException as e:  # noqa: BLE001
            failure = e

    thread = threading.Thread(target=_communicate, daemon=True)
    thread.start()

    timed_out = False
    memory_exceeded = False
    internal_error: str | None = None

    try:
        while thread.is_alive():
            if process.poll() is not None:
                break

            if (time.perf_counter() - started) > timeout_sec:
                timed_out = True
                _kill_process(process)
                break

            if memory_limit_kb is not None:
                try:
                    current_rss_kb = _process_tree_rss_kb(process.pid)
                except Exception as e:  # noqa: BLE001
                    if process.poll() is not None:
                        break
                    internal_error = f"memory monitor failure: {e}"
                    _kill_process(process)
                    break
                if current_rss_kb > memory_limit_kb:
                    memory_exceeded = True
                    _kill_process(process)
                    break

            time.sleep(0.02)
    finally:
        thread.join(timeout=2)

    elapsed_ms = int((time.perf_counter() - started) * 1000)
    if failure is not None:
        return ExecutionResult(
            stdout=_coerce_text(output.get("stdout")),
            stderr=_coerce_text(output.get("stderr")),
            exit_code=_coerce_int(output.get("exit_code")),
            elapsed_ms=elapsed_ms,
            internal_error=f"runner failure: {failure}",
        )

    return ExecutionResult(
        stdout=_coerce_text(output.get("stdout")),
        stderr=_coerce_text(output.get("stderr")),
        exit_code=_coerce_int(output.get("exit_code")),
        elapsed_ms=elapsed_ms,
        timed_out=timed_out,
        memory_exceeded=memory_exceeded,
        internal_error=internal_error,
    )


def _kill_process(process: subprocess.Popen[str]) -> None:
    try:
<<<<<<< HEAD
=======
        import psutil

        proc = psutil.Process(process.pid)
        children = proc.children(recursive=True)
        for child in reversed(children):
            try:
                child.kill()
            except psutil.Error:
                continue
        try:
            proc.kill()
            return
        except psutil.Error:
            pass
    except Exception:  # noqa: BLE001
        pass

    try:
>>>>>>> main
        process.kill()
    except OSError:
        return


def _process_tree_rss_kb(pid: int) -> int:
    try:
        import psutil
    except ImportError as e:  # pragma: no cover
        raise RuntimeError("psutil is required for memory_limit_kb support") from e

    try:
        proc = psutil.Process(pid)
    except psutil.NoSuchProcess:
        return 0
    try:
        rss = proc.memory_info().rss
    except psutil.NoSuchProcess:
        return 0
    for child in proc.children(recursive=True):
        try:
            rss += child.memory_info().rss
        except psutil.Error:
            continue
    return max(1, rss // 1024)


def _coerce_int(value: object) -> int | None:
    if value is None:
        return None
    if isinstance(value, int):
        return value
    try:
        return int(value)
    except (TypeError, ValueError):
        return None

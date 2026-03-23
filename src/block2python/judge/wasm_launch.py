from __future__ import annotations

import base64
import shlex
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


@dataclass(slots=True)
class LaunchConfig:
    command: list[str]
    process_stdin: str
    env_overrides: dict[str, str] | None = None
    cleanup: Callable[[], None] = lambda: None


def resolve_code_modes(code_mode: str) -> tuple[str, ...]:
    mode = code_mode.strip().lower()
    if mode == "inline":
        return ("inline",)
    if mode == "tempfile":
        return ("tempfile",)
    if mode == "stdin":
        return ("stdin",)
    return ("inline", "tempfile", "stdin")


def should_fallback_to_next(strategy: str, result) -> bool:
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


def build_stdin_wrapper(python_code: str) -> str:
    code_b64 = base64.b64encode(python_code.encode("utf-8")).decode("ascii")
    return (
        "import base64,io,os,sys\n"
        "sys.stdin=io.StringIO(base64.b64decode(os.environ.get('BLOCK2PYTHON_STDIN_B64','')).decode('utf-8','replace'))\n"
        f"exec(compile(base64.b64decode('{code_b64}').decode('utf-8','replace'),'<submission>','exec'))\n"
    )


def build_base_command(wasmtime_bin: str, preopen_dirs: tuple[Path, ...]) -> list[str]:
    cmd = [wasmtime_bin, "run"]
    for directory in preopen_dirs:
        cmd.extend(["--dir", str(directory)])
    return cmd


def build_python_args(base_cmd: list[str], wasm_path: Path, python_argv: tuple[str, ...], python_code: str) -> list[str]:
    cmd = list(base_cmd)
    cmd.append(str(wasm_path))
    cmd.append("--")
    if not python_argv:
        cmd.extend(["-c", python_code])
        return cmd
    for arg in python_argv:
        if arg == "{code}":
            cmd.append(python_code)
        else:
            cmd.extend(shlex.split(arg) if " " in arg else [arg])
    return cmd


def prepare_launch(
    strategy: str,
    *,
    wasmtime_bin: str,
    preopen_dirs: tuple[Path, ...],
    wasm_path: Path,
    python_argv: tuple[str, ...],
    python_code: str,
    stdin_text: str,
) -> LaunchConfig:
    base_cmd = build_base_command(wasmtime_bin, preopen_dirs)
    if strategy == "inline":
        cmd = build_python_args(base_cmd, wasm_path, python_argv, python_code)
        return LaunchConfig(command=cmd, process_stdin=stdin_text)

    if strategy == "tempfile":
        tempdir = tempfile.TemporaryDirectory(prefix="b2p_wasm_")
        host_dir = Path(tempdir.name)
        guest_dir = "/sandbox"
        script_name = "submission.py"
        script_host_path = host_dir / script_name
        script_host_path.write_text(python_code, encoding="utf-8")

        cmd = list(base_cmd)
        cmd.extend(["--dir", f"{host_dir}::{guest_dir}"])
        cmd.append(str(wasm_path))
        cmd.append("--")
        cmd.append(f"{guest_dir}/{script_name}")
        return LaunchConfig(command=cmd, process_stdin=stdin_text, cleanup=tempdir.cleanup)

    wrapped = build_stdin_wrapper(python_code)
    stdin_b64 = base64.b64encode(stdin_text.encode("utf-8")).decode("ascii")
    cmd = list(base_cmd)
    cmd.extend(["--env", f"BLOCK2PYTHON_STDIN_B64={stdin_b64}"])
    cmd.append(str(wasm_path))
    cmd.append("--")
    cmd.append("-")
    return LaunchConfig(command=cmd, process_stdin=wrapped)

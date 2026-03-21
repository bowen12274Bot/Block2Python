from __future__ import annotations

import subprocess
import threading
import time


def coerce_text(value: str | bytes | None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def coerce_int(value: object) -> int | None:
    if value is None:
        return None
    if isinstance(value, int):
        return value
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def kill_process(process: subprocess.Popen[str]) -> None:
    try:
        process.kill()
    except OSError:
        return


def process_tree_rss_kb(pid: int) -> int:
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


def monitor_process(
    execution_result_type,
    process: subprocess.Popen[str],
    stdin_text: str,
    *,
    started: float,
    timeout_sec: float,
    memory_limit_kb: int | None,
):
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
                kill_process(process)
                break

            if memory_limit_kb is not None:
                try:
                    current_rss_kb = process_tree_rss_kb(process.pid)
                except Exception as e:  # noqa: BLE001
                    if process.poll() is not None:
                        break
                    internal_error = f"memory monitor failure: {e}"
                    kill_process(process)
                    break
                if current_rss_kb > memory_limit_kb:
                    memory_exceeded = True
                    kill_process(process)
                    break

            time.sleep(0.02)
    finally:
        thread.join(timeout=2)

    elapsed_ms = int((time.perf_counter() - started) * 1000)
    if failure is not None:
        return execution_result_type(
            stdout=coerce_text(output.get("stdout")),
            stderr=coerce_text(output.get("stderr")),
            exit_code=coerce_int(output.get("exit_code")),
            elapsed_ms=elapsed_ms,
            internal_error=f"runner failure: {failure}",
        )

    return execution_result_type(
        stdout=coerce_text(output.get("stdout")),
        stderr=coerce_text(output.get("stderr")),
        exit_code=coerce_int(output.get("exit_code")),
        elapsed_ms=elapsed_ms,
        timed_out=timed_out,
        memory_exceeded=memory_exceeded,
        internal_error=internal_error,
    )

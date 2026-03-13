def main() -> int:
    from block2python.contracts import Submission

    from .core import AppCore
    from .demo_levels import demo_levels
    from .judge_factory import build_judge_from_env
    from .progress import JsonFileProgress

    judge, judge_info = build_judge_from_env()
    print("Block2Python (Demo)")
    print(judge_info)
    progress = JsonFileProgress(path=__progress_path())
    app = AppCore(demo_levels(), judge=judge, progress=progress)

    for view in app.list_levels():
        print(f"- {view.level_id}: {view.title} [{view.state}]")

    app.mark_block_passed("demo-1")
    outcome = app.submit(Submission(level_id="demo-1", python_code="print(3)"))
    print(
        f"Submit demo-1 -> analysis={outcome.analysis.status}, judge={outcome.judge.status}, "
        f"block_passed={outcome.block_passed}, cleared={outcome.cleared}"
    )

    for view in app.list_levels():
        print(f"- {view.level_id}: {view.title} [{view.state}]")
    return 0


def __progress_path():
    from pathlib import Path

    return Path(".block2python") / "progress.json"

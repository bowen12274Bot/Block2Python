def main() -> int:
    from block2python.contracts import Submission

    from .core import AppCore
    from .demo_levels import demo_levels
    from .progress import JsonFileProgress

    print("Block2Python (Demo) - app core placeholder (no real judge/analyzer yet)")
    progress = JsonFileProgress(path=__progress_path())
    app = AppCore(demo_levels(), progress=progress)

    for view in app.list_levels():
        print(f"- {view.level_id}: {view.title} [{view.state}]")

    outcome = app.submit(Submission(level_id="demo-1", python_code="print(3)"))
    print(f"Submit demo-1 -> analysis={outcome.analysis.status}, judge={outcome.judge.status}, cleared={outcome.cleared}")

    for view in app.list_levels():
        print(f"- {view.level_id}: {view.title} [{view.state}]")
    return 0


def __progress_path():
    from pathlib import Path

    return Path(".block2python") / "progress.json"
